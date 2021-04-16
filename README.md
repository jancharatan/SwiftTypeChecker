# SwiftTypeChecker
This project contains a type checker for the PCF language built in Swift using the visitor design pattern; this code was part of a final project for my CSCI181-V (Principles of Programming Languages: Object-Oriented) class at Pomona College during the Spring 2021 semester.

Here is an example of the definition for the sum function in the PCF language:

`rec (sum :: (Integer -> Integer -> Integer) => fn x: Integer => fn y: Integer => if (IsZero (x)) then (y) else (sum (Pred (x))  (Succ (y))))`

We can represent this expression using a PCFTerm as follows:

`var sumDefinition: PCFTerm = recDefTerm(fcnName: "sum", fcntp: funcFromTo(from: integerType(), to: funcFromTo(from: integerType(), to: integerType())) , body: functionTerm(param: "x", ptype: integerType(), body: functionTerm(param: "y", ptype: integerType(), body: ifCondTerm(condition: funAppTerm(fcn: isZeroTerm(), arg: iDTerm(name: "x")), thenExp: iDTerm(name: "y"), elseExp: funAppTerm(fcn: funAppTerm(fcn: iDTerm(name: "sum"), arg: funAppTerm(fcn: predTerm(), arg: iDTerm(name: "x"))), arg: funAppTerm(fcn: succTerm(), arg: iDTerm(name: "y")))))))`

We can then use our typeCheckVisitor to figure out the type of this expression. As we would expect, the type is Integer -> Integer -> Integer:

`print(sumDefinition.accept(typeCheckVisitor(env: emptyEnv)).asString())`

Note that we needed to pass a parameter of type Environment into the `typeCheckVisitor()` method. An environment simply maps strings onto types. In our sumDefinition example, we started with an empty environment, which was defined as follows:

`var emptyEnv: Environment = Env(env: [:])` 
