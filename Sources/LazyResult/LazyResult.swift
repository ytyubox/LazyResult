/// A value that lazy represents either a success or a failure, including an associated value in each case.
@frozen
public enum LazyResult<Success,Failure> where Failure: Error{
	/// A unInit, storing a clousure to perform later.
	case unInit(() throws -> Success)
	/// A success, storing a `Success` value.
	case success(Success)
	/// A failure, storing a `Failure` value.
	case failure(Failure)
	
	public mutating func perform() {
		guard case .unInit(let body) = self else {return}
		do {
			self = .success(try body())
		}catch {
			self = .failure(error as! Failure)
		}
		
	}
	/// Returns a new Swift.Result, and change to .success if self is .unInit
	public
	mutating
	func toResult() -> Result<Success,Failure> {
		switch self {
		case let .unInit(body):
			do {
				let t = try body()
				self = .success(t)
				return .success(t)
			} catch let blockError{
				return .failure(blockError as! Failure)
			}
		case let .success(success): return .success(success)
		case let .failure(failure): return .failure(failure)
		}
	}
	/// Returns the success value as a throwing expression.
	///
	/// Use this method to retrieve the value of this lazy result if it represents a
	/// success, or to catch the value if it represents a failure.
	///
	///     let integerResult: LazyResult<Int, Error> = .success(5)
	///     do {
	///         let value = try integerResult.get()
	///         print("The value is \(value).")
	///     } catch error {
	///         print("Error retrieving the value: \(error)")
	///     }
	///     // Prints "The value is 5."
	///
	/// - Returns: The success value, if the instance represents a success.
	/// - Throws: The failure value, if the instance represents a failure.
	public
	mutating
	func get() throws -> Success {
		try toResult().get()
	}
	/// Returns a new lazy result, mapping any success value using the given
	/// transformation.
	///
	/// Use this method when you need to transform the value of a `LasyResult`
	/// instance when it represents a success. The following example transforms
	/// the integer success value of a Lazyresult into a string:
	///
	///     func getNextInteger() -> LazyResult<Int, Error> { /* ... */ }
	///
	///     let integerResult = getNextInteger()
	///     // integerResult == .success(5)
	///     let stringResult = integerResult.map({ String($0) })
	///     // stringResult == .success("5")
	///
	/// - Parameter transform: A closure that takes the success value of this
	///   instance.
	/// - Returns: A `LazyResult` instance with the lazy result of evaluating `transform`
	///   as the new success value if this instance represents a success.
	public func map<NewSuccess>(
		_ transform: @escaping (Success) -> NewSuccess
	) -> LazyResult<NewSuccess, Failure> {
		switch self {
		case let  .unInit(body):
			let newBody = {
				return try transform(body())
			}
			return .unInit(newBody)
		case let .success(success): return .success(transform(success))
		case let .failure(failure): return .failure(failure)
		}
	}
	/// Returns a new lazy result, mapping any failure value using the given
	/// transformation.
	///
	/// Use this method when you need to transform the value of a `LazyResult`
	/// instance when it represents a failure. The following example transforms
	/// the error value of a result by wrapping it in a custom `Error` type:
	///
	///     struct DatedError: Error {
	///         var error: Error
	///         var date: Date
	///
	///         init(_ error: Error) {
	///             self.error = error
	///             self.date = Date()
	///         }
	///     }
	///
	///     let result: LazyResult<Int, Error> = // ...
	///     // result == .failure(<error value>)
	///     let resultWithDatedError = result.mapError({ e in DatedError(e) })
	///     // result == .failure(DatedError(error: <error value>, date: <date>))
	///
	/// - Parameter transform: A closure that takes the failure value of the
	///   instance.
	/// - Returns: A `LazyResult` instance with the lazy result of evaluating `transform`
	///   as the new failure value if this instance represents a failure.
	public func mapError<NewFailure>(
		_ transform: @escaping (Failure) -> NewFailure
	) -> LazyResult<Success, NewFailure> {
		switch self {
		case let .unInit(body):
			let newBody = { () -> Success in
				do { return try body()}
				catch {
					throw transform(error as! Failure)
				}
			}
			return .unInit(newBody)
		case let .success(success):
			return .success(success)
		case let .failure(failure):
			return .failure(transform(failure))
		}
	}
	/// Returns a new lazy result, mapping any success value using the given
	/// transformation and unwrapping the produced result.
	///
	/// - Parameter transform: A closure that takes the success value of the
	///   instance.
	/// - Returns: A `LazyResult` instance with the result of evaluating `transform`
	///   as the new failure value if this instance represents a failure.
	public func flatMap<NewSuccess>(
		_ transform: @escaping (Success) -> LazyResult<NewSuccess, Failure>
	) -> LazyResult<NewSuccess, Failure> {
		switch self {
		case let .unInit(body):
			let newBody: () throws -> NewSuccess = {
				var newLazy = try transform(body())
				return try newLazy.get()
			}
			return .unInit(newBody)
		case let .success(success):
			return transform(success)
		case let .failure(failure):
			return .failure(failure)
		}
	}
	/// Returns a new lazy result, mapping any failure value using the given
	/// transformation and unwrapping the produced result.
	///
	/// - Parameter transform: A closure that takes the failure value of the
	///   instance.
	/// - Returns: A `Lavy Result` instance, either from the closure or the previous
	///   `.success`.
	public func flatMapError<NewFailure>(
		_ transform: @escaping (Failure) -> LazyResult<Success, NewFailure>
	) -> LazyResult<Success, NewFailure> {
		switch self {
		case let .unInit(body):
			let newBody: () throws -> Success = {
				do {
					return try body()
				}catch {
					let newResult = transform(error as! Failure)
					switch newResult {
					case let .unInit(newResultBody):
						do { return try newResultBody() }
						catch {throw error}
					case let .success(success): return success
					case let .failure(failure): throw failure
					}
				}
			}
			return .unInit(newBody)
		case let .success(success):
			return .success(success)
		case let .failure(failure):
			return transform(failure)
		}
	}
}

extension LazyResult where Failure == Swift.Error {
	/// Creates a new lazy result by capture a throwing closure, which will capturing the
	/// returned value as a success, or any thrown error as a failure in the future.
	///
	/// - Parameter body: A throwing closure to evaluate later.
	@_transparent
	public init(catching body:@escaping () throws -> Success) {
		self = .unInit(body)
	}
}
