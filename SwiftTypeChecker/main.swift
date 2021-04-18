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

// Interface for a function type; extension of PCFType
protocol PairType: PCFType {
    var fst: PCFType { get set }
    var snd: PCFType { get set }
}

// Custom defined errors.
enum TypeError : Error {
    case EnvError
    case NotFuncError
    case FuncMatchError
    case RecError
    case CondError
    case TypeMatchError
    case InputError
}

// Interface for a Visitor
protocol Visitor {
    func visitID(id: String) throws -> PCFType
    func visitNum(n: Int) -> PCFType
    func visitBool(b: Bool) -> PCFType
    func visitSucc() -> PCFType
    func visitPred() -> PCFType
    func visitIsZero() -> PCFType
    func visitFunParam(param: String, pType: PCFType, b: PCFTerm) -> PCFType
    func visitFunApp(fcn: PCFTerm, arg: PCFTerm) throws -> PCFType
    func visitRecDef(name: String, rType: PCFType, b: PCFTerm) throws -> PCFType
    func visitCond(condVal: PCFTerm, tExpVal: PCFTerm, eExpVal: PCFTerm) throws -> PCFType
    func visitLet(s: String, tp: PCFType, lexp: PCFTerm, exp: PCFTerm) throws -> PCFType
    func visitPair(fst: PCFTerm, snd: PCFTerm) -> PCFType
    func visitFirst(pair: PCFTerm) throws -> PCFType
    func visitSecond(pair: PCFTerm) throws -> PCFType
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
        do {
            return try visitor.visitID(id: name)
        } catch TypeError.EnvError {
            return errorType()
        } catch {
            return errorType()
        }
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
        return "fn \(param): \(ptype.asString()) => \(body.asString())"
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
        do {
            return try visitor.visitFunApp(fcn: fcn, arg: arg)
        } catch TypeError.FuncMatchError {
            return errorType()
        } catch TypeError.NotFuncError {
            return errorType()
        } catch {
            return errorType()
        }
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
        return "rec (\(fcnName): \(fcntp.asString()) => \(body.asString()))"
    }
    func accept(_ visitor: Visitor) -> PCFType {
        do {
            return try visitor.visitRecDef(name: fcnName, rType: fcntp, b: body)
        } catch TypeError.RecError {
            return errorType()
        } catch {
            return errorType()
        }
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
        do {
            return try visitor.visitCond(condVal: condition, tExpVal: thenExp, eExpVal: elseExp)
        } catch TypeError.CondError {
            return errorType()
        } catch {
            return errorType()
        }
    }
}

// Let expression.
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
        do {
            return try visitor.visitLet(s: s, tp: tp, lexp: lexp, exp: exp)
        } catch TypeError.TypeMatchError {
            return errorType()
        } catch {
            return errorType()
        }
    }
}

// Tuple.
class pairTerm: PCFTerm {
    var fst: PCFTerm
    var snd: PCFTerm
    init(fst: PCFTerm, snd: PCFTerm) {
        self.fst = fst
        self.snd = snd
    }
    func asString() -> String {
        return "(\(fst.asString()), \(snd.asString()))"
    }
    func accept(_ visitor: Visitor) -> PCFType {
        return visitor.visitPair(fst: fst, snd: snd)
    }
}

// Gets first element from tuple.
class fstTerm: PCFTerm {
    var pair: PCFTerm
    init(pair: PCFTerm) {
        self.pair = pair
    }
    func asString() -> String {
        return "first (\(pair.asString()))"
    }
    func accept(_ visitor: Visitor) -> PCFType {
        do {
            return try visitor.visitFirst(pair: pair)
        } catch TypeError.InputError {
            return errorType()
        } catch {
            return errorType()
        }
    }
}

// Gets second element from tuple.
class sndTerm: PCFTerm {
    var pair: PCFTerm
    init(pair: PCFTerm) {
        self.pair = pair
    }
    func asString() -> String {
        return "second (\(pair.asString()))"
    }
    func accept(_ visitor: Visitor) -> PCFType {
        do {
            return try visitor.visitSecond(pair: pair)
        } catch TypeError.InputError {
            return errorType()
        } catch {
            return errorType()
        }
    }
}

// this class will be returned if the type cannot be figured out/if there is an error.
class errorType: PCFType {
    func isEqualTo(_ other: PCFType) -> Bool {
        return other is errorType
    }
    func asString() -> String {
        return "Error"
    }
    
}

// this class represents an integer type.
class integerType: PCFType {
    func isEqualTo(_ other: PCFType) -> Bool {
        return other is integerType
    }
    func asString() -> String {
        return "Integer"
    }
    
}

// this class represents the boolean type.
class booleanType: PCFType {
    func isEqualTo(_ other: PCFType) -> Bool {
        return other is booleanType
    }
    func asString() -> String {
        return "Boolean"
    }
}

// this is a class that implements the pairtype protocol; represents a pair made up of two types.
class pairType: PairType {
    var fst: PCFType
    var snd: PCFType
    init(fst: PCFType, snd: PCFType) {
        self.fst = fst
        self.snd = snd
    }
    func isEqualTo(_ other: PCFType) -> Bool {
        switch other {
            case let other as PairType:
                if ((fst.isEqualTo(other.fst)) && (snd.isEqualTo(other.snd))) {
                    return true
                }
            default:
                return false
        }
        return false
    }
    func asString() -> String {
        return "(\(fst.asString()), \(snd.asString()))"
    }
}

// this is a class that implements the functiontype protocol; represents a function from one type to another.
class funcFromTo: FunctionType {
    var domain: PCFType
    var range: PCFType
    init(domain: PCFType, range: PCFType) {
        self.domain = domain
        self.range = range
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
    func visitID(id: String) throws -> PCFType {
        if let tp = env.dictionary[id] {
            return tp
        }
        throw TypeError.EnvError
    }
    func visitNum(n: Int) -> PCFType {
        return integerType()
    }
    func visitBool(b: Bool) -> PCFType {
        return booleanType()
    }
    func visitSucc() -> PCFType {
        return funcFromTo(domain: integerType(), range: integerType())
    }
    func visitPred() -> PCFType {
        return funcFromTo(domain: integerType(), range: integerType())
    }
    func visitIsZero() -> PCFType {
        return funcFromTo(domain: integerType(), range: booleanType())
    }
    func visitFunParam(param: String, pType: PCFType, b: PCFTerm) -> PCFType {
        var nextEnv: Environment = env
        nextEnv.dictionary[param] = pType
        let bodyType: PCFType = b.accept(typeCheckVisitor(env: nextEnv))
        return funcFromTo(domain: pType, range: bodyType)
    }
    func visitFunApp(fcn: PCFTerm, arg: PCFTerm) throws -> PCFType {
        switch(fcn.accept(self)) {
            case let fn as FunctionType:
                if (fn.domain.isEqualTo(arg.accept(self))) {
                    return fn.range
                } else {
                    throw TypeError.FuncMatchError
                }
            default:
                throw TypeError.NotFuncError
        }
    }
    func visitRecDef(name: String, rType: PCFType, b: PCFTerm) throws -> PCFType {
        var nextEnv: Environment = env
        nextEnv.dictionary[name] = rType
        let bodyType: PCFType = b.accept(typeCheckVisitor(env: nextEnv))
        if (bodyType.isEqualTo(rType)) {
            return rType
        } else {
            throw TypeError.RecError
        }
    }
    func visitCond(condVal: PCFTerm, tExpVal: PCFTerm, eExpVal: PCFTerm) throws -> PCFType {
        let tType: PCFType = tExpVal.accept(self)
        if ((condVal.accept(self)).isEqualTo(booleanType()) && tType.isEqualTo(eExpVal.accept(self))) {
            return tType
        } else {
            throw TypeError.CondError
        }
    }
    func visitLet(s: String, tp: PCFType, lexp: PCFTerm, exp: PCFTerm) throws -> PCFType {
        var nextEnv: Environment = env
        nextEnv.dictionary[s] = tp
        let lexptp: PCFType = lexp.accept(typeCheckVisitor(env: emptyEnv))
        let exptp: PCFType = exp.accept(typeCheckVisitor(env: nextEnv))
        if (lexptp.isEqualTo(tp)) {
            return exptp
        } else {
            throw TypeError.TypeMatchError
        }
    }
    func visitPair(fst: PCFTerm, snd: PCFTerm) -> PCFType {
        let tpFst: PCFType = fst.accept(typeCheckVisitor(env: emptyEnv))
        let tpSnd: PCFType = snd.accept(typeCheckVisitor(env: emptyEnv))
        return pairType(fst: tpFst, snd: tpSnd)
    }
    func visitFirst(pair: PCFTerm) throws -> PCFType {
        let pairTp: PCFType = pair.accept(typeCheckVisitor(env: emptyEnv))
        switch pairTp {
        case let p as PairType:
            return p.fst
        default:
            throw TypeError.InputError
        }
    }
    func visitSecond(pair: PCFTerm) throws -> PCFType {
        let pairTp: PCFType = pair.accept(typeCheckVisitor(env: emptyEnv))
        switch pairTp {
        case let p as PairType:
            return p.snd
        default:
            throw TypeError.InputError
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
var test5: PCFTerm = recDefTerm(fcnName: "sum", fcntp: funcFromTo(domain: integerType(), range: funcFromTo(domain: integerType(), range: integerType())) , body: functionTerm(param: "x", ptype: integerType(), body: functionTerm(param: "y", ptype: integerType(), body: ifCondTerm(condition: funAppTerm(fcn: isZeroTerm(), arg: iDTerm(name: "x")), thenExp: iDTerm(name: "y"), elseExp: funAppTerm(fcn: funAppTerm(fcn: iDTerm(name: "sum"), arg: funAppTerm(fcn: predTerm(), arg: iDTerm(name: "x"))), arg: funAppTerm(fcn: succTerm(), arg: iDTerm(name: "y")))))))
print("Type of \(test5.asString()) is:")
print(test5.accept(typeCheckVisitor(env: emptyEnv)).asString())

// test the type of a let expression.
var test6: PCFTerm = letTerm(s: "f", tp: funcFromTo(domain: integerType(), range: integerType()), lexp: functionTerm(param: "x", ptype: integerType(), body: funAppTerm(fcn: succTerm(), arg: iDTerm(name: "x"))), exp: funAppTerm(fcn: iDTerm(name: "f"), arg: numTerm(number: 0)))
print("Type of \(test6.asString()) is:")
print(test6.accept(typeCheckVisitor(env: emptyEnv)).asString())

// test the type of a pair.
var test7: PCFTerm = pairTerm(fst: test1, snd: boolTerm(value: true))
print("Type of \(test7.asString()) is:")
print(test7.accept(typeCheckVisitor(env: emptyEnv)).asString())

// test the type of the second item in previous pair.
var test8: PCFTerm = sndTerm(pair: test7)
print("Type of \(test8.asString()) is:")
print(test8.accept(typeCheckVisitor(env: emptyEnv)).asString())

// test that the error handling mechanism works correctly, successor of bool should be an error.
var test9: PCFTerm = funAppTerm(fcn: succTerm(), arg: boolTerm(value: true))
print("Type of \(test9.asString()) is:")
print(test9.accept(typeCheckVisitor(env: emptyEnv)).asString())
