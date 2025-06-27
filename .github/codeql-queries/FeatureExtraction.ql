/**
 * @name Extract Features for Cohesion Analysis
 * @description This query extracts all referenced symbols (functions, variables, types) for each source file.
 * @kind table
 */
import cpp

// 辅助函数：获取一个元素的完全限定名
string getQualifiedName(Element e) {
  e.(Function).hasGlobalOrStdName() and result = e.(Function).getQualifiedName()
  or
  e.(Variable).hasGlobalOrStdName() and result = e.(Variable).getQualified_name()
  or
  // 对于类型，我们直接用它的名字
  result = e.(Type).getName()
}

// 主查询：联合三种不同类型的引用
from File f, Element ref, string featureType
where
  // 条件1：我们只关心源文件和头文件
  (f.getExtension() = "cpp" or f.getExtension() = "h" or f.getExtension() = "hpp") and
  // 条件2：我们只关心我们模块内的文件
  f.getRelativePath().matches("src/brpc/%") and
  (
    // 特征类型A：函数调用
    exists(Call c |
      c.getEnclosingFunction().getFile() = f and
      ref = c.getTarget() and
      featureType = "FunctionCall"
    )
    or
    // 特征类型B：变量访问
    exists(VariableAccess va |
      va.getEnclosingFunction().getFile() = f and
      ref = va.getTarget() and
      featureType = "VariableAccess"
    )
    or
    // 特征类型C：类型访问
    exists(TypeAccess ta |
      ta.getEnclosingFunction().getFile() = f and
      ref = ta.getType() and
      featureType = "TypeAccess"
    )
  )
// 输出结果：文件名，特征类型，特征的完全限定名
select f.getRelativePath() as file, featureType, getQualifiedName(ref) as feature
