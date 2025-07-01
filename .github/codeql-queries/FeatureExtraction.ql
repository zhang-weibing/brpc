# 文件路径: .github/codeql-queries/FeatureExtraction.ql

/**
 * @name Extract Features for Cohesion Analysis (v3 - Corrected)
 * @description This query extracts all referenced functions, variables and types for each source file.
 * @kind table
 */
import cpp

// 辅助函数，用于获取元素的唯一标识符
private string getAnElementSignature(Element e) {
  // 对于函数，获取其签名
  exists(Function f | e = f and result = f.getSignature())
  or
  // 对于变量，获取其限定名
  exists(Variable v | e = v and result = v.getQualifiedName())
  or
  // 对于类型，获取其名称
  exists(Type t | e = t and result = t.getQualifiedName())
}

from Expr e, File f
where
  // 条件1：我们只关心我们模块内的文件
  f.getRelativePath().matches("src/brpc/%") and
  // 条件2：表达式e位于文件f中
  e.getFile() = f and
  (
    // 特征类型A：函数调用
    exists(FunctionCall fc | e = fc and
      // 我们关心被调用的函数
      getAnElementSignature(fc.getTarget()) != ""
    )
    or
    // 特征类型B：变量访问
    exists(VariableAccess va | e = va and
      // 我们关心被访问的变量
      getAnElementSignature(va.getTarget()) != ""
    )
    or
    // 特征类型C：类型访问
    exists(TypeAccess ta | e = ta and
      // 我们关心被访问的类型
      getAnElementSignature(ta.getType()) != ""
    )
  )
// 输出结果
select
  f.getRelativePath() as file,
  // 根据表达式的类型来确定特征类型
  e.getAPrimaryQlClass() as featureType,
  // 根据表达式的类型来获取特征
  (
    if e instanceof FunctionCall then getAnElementSignature(e.(FunctionCall).getTarget()) else
    if e instanceof VariableAccess then getAnElementSignature(e.(VariableAccess).getTarget()) else
    if e instanceof TypeAccess then getAnElementSignature(e.(TypeAccess).getType()) else ""
  ) as feature
