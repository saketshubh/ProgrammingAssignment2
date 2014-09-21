## The following functions return the cached inverse of a matrix


## The function makeCacheMatrix creates a special "matrix" object which can cache its inverse.

makeCacheMatrix <- function(x = matrix()) {
	inv <- NULL
	set <- function(y) {
	         x <<- y
	         inv <<- NULL
	     }
	get <- function() {
	x
	}
      setinverse <- function(inverse) inv <<- inverse
      getinverse <- function() inv
      list(set=set, get=get, setinverse=setinverse, getinverse=getinverse)
}


## The function cacheSolve computes the inverse of the special "matrix" returned by makeCacheMatrix above
## This function assumes that the matrix is invertible i.e. its Determinant is non-zero

cacheSolve <- function(x, ...) {
inv <- x$getinverse()
    if(!is.null(inv)) {
        message("getting cached data.")
        return(inv)
    }
    data <- x$get()
    inv <- solve(data)
    x$setinverse(inv)
    inv       
}
