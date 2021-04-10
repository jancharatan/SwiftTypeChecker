//
//  main.swift
//  A type checker for the PCF language made in Swift.
//
//  Created by Jan Charatan on 4/8/21.

import Foundation

// Interface for terms of the PCF language.
protocol PCFTerm {
    func accept(_ visitor: Visitor) -> PCFType
    func asString() -> String
}

// Interface for PCF Types, supports equality
protocol PCFType {
    func isEqualTo(_ other: PCFType) -> Bool
    func asString() -> String
}

// Interface for a function type; extension of PCFType
protocol FunctionType: PCFType {
    var domain: PCFType { get set }
    var range: PCFType { get set }
}

// Interface for a Visitor
protocol Visitor {
    func visitID(id: String) -> PCFType
    func visitNum(n: Int) -> PCFType
    func visitBool(b: Bool) -> PCFType
    func visitSucc() -> PCFType
    func visitPred() -> PCFType
    func visitIsZero() -> PCFType
    func visitFunParam(param: String, pType: PCFType, b: PCFTerm) -> PCFType
    func visitFunApp(fcn: PCFTerm, arg: PCFTerm) -> PCFType
    func visitRecDef(name: String, rType: PCFType, b: PCFTerm) -> PCFType
    func visitCond(condVal: PCFTerm, tExpVal: PCFTerm, eExpVal: PCFTerm) -> PCFType
    func visitLet(s: String, tp: PCFType, lexp: PCFTerm, exp: PCFTerm) -> PCFType
}

// Interface for an environment.
protocol Environment {
    var dictionary: Dictionary<String, PCFType> { get set }
}

// Identifier with name.
class iDTerm: PCFTerm {
    var name: String
    init(name: String) {
        self.name = name
    }
    func asString() -> String {
        return name
    }
    func accept(_ visitor: Visitor) -> PCFType {
        return visitor.visitID(id: name)
    }
}

// Number with value.
class numTerm: PCFTerm {
    var number: Int
    init(number: Int) {
        self.number = number
    }
    func asString() -> String {
        return "\(number)"
    }
    func accept(_ visitor: Visitor) -> PCFType {
        return visitor.visitNum(n: number)
    }
}

// Boolean term with value.
class boolTerm: PCFTerm {
    var value: Bool
    init(value: Bool) {
        self.value = value
    }
    func asString() -> String {
        return "\(value)"
    }
    func accept (_ visitor: Visitor) -> PCFType {
        return visitor.visitBool(b: value)
    }
}

// Successor function
class succTerm: PCFTerm {
    func asString() -> String {
        return "Succ"
    }
    func accept (_ visitor: Visitor) -> PCFType {
        return visitor.visitSucc()
    }
}

// Predecessor function
class predTerm: PCFTerm {
    func asString() -> String {
        return "Pred"
    }
    func accept (_ visitor: Visitor) -> PCFType {
        return visitor.visitPred()
    }
}

// IsZero function
class isZeroTerm: PCFTerm {
    func asString() -> String {
        return "IsZero"
    }
    func accept (_ visitor: Visitor) -> PCFType {
        return visitor.visitIsZero()
    }
}

// Function with parameter of a certain type.
class functionTerm: PCFTerm {
    var param: String
    var ptype: PCFType
    var body: PCFTerm
    init(param: String, ptype: PCFType, body: PCFTerm) {
        self.param = param
        self.ptype = ptype
        self.body = body
    }
    func asString() -> String {
        return "fn \(param):\(ptype.asString()) => \(body.asString())"
    }
    func accept (_ visitor: Visitor) -> PCFType {
        return visitor.visitFunParam(param: param, pType: ptype, b: body)
    }
}

// Function that is applied to another term.
class funAppTerm: PCFTerm {
    var fcn: PCFTerm
    var arg: PCFTerm
    init(fcn: PCFTerm, arg: PCFTerm) {
        self.fcn = fcn
        self.arg = arg
    }
    func asString() -> String {
        return "\(fcn.asString()) (\(arg.asString()))"
    }
    func accept(_ visitor: Visitor) -> PCFType {
        return visitor.visitFunApp(fcn: fcn, arg: arg)
    }
}

// Recursively defined function.
class recDefTerm: PCFTerm {
    var fcnName: String
    var fcntp: PCFType
    var body: PCFTerm
    init(fcnName: String, fcntp: PCFType, body: PCFTerm) {
        self.fcnName = fcnName
        self.fcntp = fcntp
        self.body = body
    }
    func asString() -> String {
        return "\(fcnName):\(fcntp.asString()) => \(body.asString())"
    }
    func accept(_ visitor: Visitor) -> PCFType {
        return visitor.visitRecDef(name: fcnName, rType: fcntp, b: body)
    }
}

// If, then, else expression.
class ifCondTerm: PCFTerm {
    var condition: PCFTerm
    var thenExp: PCFTerm
    var elseExp: PCFTerm
    init(condition: PCFTerm, thenExp: PCFTerm, elseExp: PCFTerm) {
        self.condition = condition
        self.thenExp = thenExp
        self.elseExp = elseExp
    }
    func asString() -> String {
        return "if (\(condition.asString())) then (\(thenExp.asString())) else (\(elseExp.asString()))"
    }
    func accept(_ visitor: Visitor) -> PCFType {
        return visitor.visitCond(condVal: condition, tExpVal: thenExp, eExpVal: elseExp)
    }
}

class letTerm: PCFTerm {
    var s: String
    var tp: PCFType
    var lexp: PCFTerm
    var exp: PCFTerm
    init(s: String, tp: PCFType, lexp: PCFTerm, exp: PCFTerm) {
        self.s = s
        self.tp = tp
        self.lexp = lexp
        self.exp = exp
    }
    func asString() -> String {
        return "let \(s): \(tp.asString()) = \(lexp.asString()) in \(exp.asString())"
    }
    func accept(_ visitor: Visitor) -> PCFType {
        return visitor.visitLet(s: s, tp: tp, lexp: lexp, exp: exp)
    }
}

// this class will be returned if the type cannot be figured out/if there is an error.
class errorType: PCFType {
    func isEqualTo(_ other: PCFType) -> Bool {
        if other is errorType {
            return true
        } else {
            return false
        }
    }
    func asString() -> String {
        return "Error"
    }
    
}

// this class represents an integer type.
class integerType: PCFType {
    func isEqualTo(_ other: PCFType) -> Bool {
        if other is integerType {
            return true
        } else {
            return false
        }
    }
    func asString() -> String {
        return "Integer"
    }
    
}

// this class represents the boolean type.
class booleanType: PCFType {
    func isEqualTo(_ other: PCFType) -> Bool {
        if other is booleanType {
            return true
        } else {
            return false
        }
    }
    func asString() -> String {
        return "Boolean"
    }
}

// this is a class that implements the functiontype protocol; represents a function from one type to another.
class funcFromTo: FunctionType {
    var domain: PCFType
    var range: PCFType
    init(from: PCFType, to: PCFType) {
        domain = from
        range = to
    }
    func isEqualTo(_ other: PCFType) -> Bool {
        switch other {
            case let other as FunctionType:
                if ((domain.isEqualTo(other.domain)) && (range.isEqualTo(other.range))) {
                    return true
                }
            default:
                return false
        }
        return false
    }
    func asString() -> String {
        return "\(domain.asString()) -> \(range.asString())"
    }
}

// this is the visitor that checks the type of an expression.
class typeCheckVisitor: Visitor {
    var env: Environment
    init(env: Environment) {
        self.env = env
    }
    func visitID(id: String) -> PCFType {
        if let tp = env.dictionary[id] {
            return tp
        }
        return errorType()
    }
    func visitNum(n: Int) -> PCFType {
        return integerType()
    }
    func visitBool(b: Bool) -> PCFType {
        return booleanType()
    }
    func visitSucc() -> PCFType {
        return funcFromTo(from: integerType(), to: integerType())
    }
    func visitPred() -> PCFType {
        return funcFromTo(from: integerType(), to: integerType())
    }
    func visitIsZero() -> PCFType {
        return funcFromTo(from: integerType(), to: booleanType())
    }
    func visitFunParam(param: String, pType: PCFType, b: PCFTerm) -> PCFType {
        var nextEnv: Environment = env
        nextEnv.dictionary[param] = pType
        let bodyType: PCFType = b.accept(typeCheckVisitor(env: nextEnv))
        return funcFromTo(from: pType, to: bodyType)
    }
    func visitFunApp(fcn: PCFTerm, arg: PCFTerm) -> PCFType {
        switch(fcn.accept(self)) {
            case let fn as FunctionType:
                if (fn.domain.isEqualTo(arg.accept(self))) {
                    return fn.range
                } else {
                    return errorType()
                }
            default:
                return errorType()
        }
    }
    func visitRecDef(name: String, rType: PCFType, b: PCFTerm) -> PCFType {
        var nextEnv: Environment = env
        nextEnv.dictionary[name] = rType
        let bodyType: PCFType = b.accept(typeCheckVisitor(env: nextEnv))
        if (bodyType.isEqualTo(rType)) {
            return rType
        } else {
            return errorType()
        }
    }
    func visitCond(condVal: PCFTerm, tExpVal: PCFTerm, eExpVal: PCFTerm) -> PCFType {
        let tType: PCFType = tExpVal.accept(self)
        if ((condVal.accept(self)).isEqualTo(booleanType()) && tType.isEqualTo(eExpVal.accept(self))) {
            return tType
        } else {
            return errorType()
        }
    }
    func visitLet(s: String, tp: PCFType, lexp: PCFTerm, exp: PCFTerm) -> PCFType {
        var nextEnv: Environment = env
        nextEnv.dictionary[s] = tp
        let lexptp: PCFType = lexp.accept(typeCheckVisitor(env: emptyEnv))
        let exptp: PCFType = exp.accept(typeCheckVisitor(env: nextEnv))
        if (lexptp.isEqualTo(tp)) {
            return exptp
        } else {
            return errorType()
        }
    }
}

// This is the environment class, it takes in a dictionary that will associate strings with types.
class Env: Environment {
    var dictionary: Dictionary<String, PCFType>
    init(env: Dictionary<String, PCFType>) {
        dictionary = env
    }
}

// Tests:

// create an empty environment for the tests.
var emptyEnv: Environment = Env(env: [:])

// test the type of the successor function applied to the number 47.
var test1: PCFTerm = funAppTerm(fcn: succTerm(), arg: numTerm(number: 47))
print("Type of \(test1.asString()) is:")
print(test1.accept(typeCheckVisitor(env: emptyEnv)).asString())

// test the type of an if/else condition that should return an integer.
var test2: PCFTerm = ifCondTerm(condition: boolTerm(value: true), thenExp: test1, elseExp: (numTerm(number: 0)))
print("Type of \(test2.asString()) is:")
print(test2.accept(typeCheckVisitor(env: emptyEnv)).asString())

// test the type of the identity function.
var test3: PCFTerm = functionTerm(param: "x", ptype: integerType(), body: iDTerm(name: "x"))
print("Type of \(test3.asString()) is:")
print(test3.accept(typeCheckVisitor(env: emptyEnv)).asString())

// test the type of the identity function applied to the number 47.
var test4: PCFTerm = funAppTerm(fcn: test3, arg: numTerm(number: 47))
print("Type of \(test4.asString()) is:")
print(test4.accept(typeCheckVisitor(env: emptyEnv)).asString())

// test the type of the definition of sum, a recursively defined function.
var test5: PCFTerm = recDefTerm(fcnName: "sum", fcntp: funcFromTo(from: integerType(), to: funcFromTo(from: integerType(), to: integerType())) , body: functionTerm(param: "x", ptype: integerType(), body: functionTerm(param: "y", ptype: integerType(), body: ifCondTerm(condition: funAppTerm(fcn: isZeroTerm(), arg: iDTerm(name: "x")), thenExp: iDTerm(name: "y"), elseExp: funAppTerm(fcn: funAppTerm(fcn: iDTerm(name: "sum"), arg: funAppTerm(fcn: predTerm(), arg: iDTerm(name: "x"))), arg: funAppTerm(fcn: succTerm(), arg: iDTerm(name: "y")))))))
print("Type of \(test5.asString()) is:")
print(test5.accept(typeCheckVisitor(env: emptyEnv)).asString())

// test the type of a let expression.
var test6: PCFTerm = letTerm(s: "f", tp: funcFromTo(from: integerType(), to: integerType()), lexp: functionTerm(param: "x", ptype: integerType(), body: funAppTerm(fcn: succTerm(), arg: iDTerm(name: "x"))), exp: funAppTerm(fcn: iDTerm(name: "f"), arg: numTerm(number: 0)))
print("Type of \(test6.asString()) is:")
print(test6.accept(typeCheckVisitor(env: emptyEnv)).asString())
