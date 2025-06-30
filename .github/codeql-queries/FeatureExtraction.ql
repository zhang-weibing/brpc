/**
 * @name Extract Features for Cohesion Analysis (v3 - Corrected)
 * @description This query extracts all referenced functions, variables and types for each source file.
 * @kind table
 */
import cpp

// 辅助函数，用于获取元素的唯一、可读的标识符
private string getAnElementSignature(Element e) {
  // 对于函数，获取其唯一的函数签名
  exists(Function f | e = f and result = f.getSignature())
  or
  // 对于变量，获取其完全限定名
  exists(Variable v | e = v and result = v.getQualifiedName())
  or
  // 对于类型，获取其完全限定名
  exists(Type t | e = t and result = t.getQualifiedName())
}

// 主查询，从所有“表达式”开始
from Expr e, File f
where
  // 条件1：我们只关心我们模块内的文件
  f.getRelativePath().matches("src/brpc/%") and
  // 条件2：这个表达式必须位于我们关心的文件f中
  e.getFile() = f and
  // 条件3：这个表达式必须是我们关心的三种类型之一
  (
    // 特征类型A：函数调用
    exists(FunctionCall fc | e = fc and
      // 并且我们能成功获取被调用函数的签名（过滤掉一些无法解析的内部调用）
      getAnElementSignature(fc.getTarget()) != ""
    )
    or
    // 特征类型B：变量访问
    exists(VariableAccess va | e = va and
      // 并且我们能成功获取被访问变量的名称
      getAnElementSignature(va.getTarget()) != ""
    )
    or
    // 特征类型C：类型访问
    exists(TypeAccess ta | e = ta and
      // 并且我们能成功获取被访问类型的名称
      getAnElementSignature(ta.getType()) != ""
    )
  )
// 输出结果
select
  // 第1列：文件名
  f.getRelativePath() as file,
  // 第2列：特征类型（比如是"FunctionCall", "VariableAccess"等）
  e.getAPrimaryQlClass() as featureType,
  // 第3列：特征本身（函数签名、变量名或类型名）
  (
    if e instanceof FunctionCall then getAnElementSignature(e.(FunctionCall).getTarget()) else
    if e instanceof VariableAccess then getAnElementSignature(e.(VariableAccess).getTarget()) else
    if e instanceof TypeAccess then getAnElementSignature(e.(TypeAccess).getType()) else ""
  ) as feature
