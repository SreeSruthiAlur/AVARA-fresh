from fastapi import Request, status
from fastapi.responses import JSONResponse
import logging

logger = logging.getLogger("avara.errors")

class AppError(Exception):
    def __init__(self, message: str, status_code: int = status.HTTP_400_BAD_REQUEST, error_code: str = "BAD_REQUEST", details: dict = None):
        super().__init__(message)
        self.message = message
        self.status_code = status_code
        self.error_code = error_code
        self.details = details or {}

class UnauthorizedError(AppError):
    def __init__(self, message: str = "Invalid or expired authentication credentials"):
        super().__init__(message=message, status_code=status.HTTP_401_UNAUTHORIZED, error_code="UNAUTHORIZED")

class ForbiddenError(AppError):
    def __init__(self, message: str = "You do not have permission to access this resource"):
        super().__init__(message=message, status_code=status.HTTP_403_FORBIDDEN, error_code="FORBIDDEN")

class NotFoundError(AppError):
    def __init__(self, message: str = "Resource not found"):
        super().__init__(message=message, status_code=status.HTTP_404_NOT_FOUND, error_code="NOT_FOUND")

class ConflictError(AppError):
    def __init__(self, message: str = "Resource conflict"):
        super().__init__(message=message, status_code=status.HTTP_409_CONFLICT, error_code="CONFLICT")

async def app_error_handler(request: Request, exc: AppError):
    logger.warning(f"Handled application error: {exc.error_code} - {exc.message} on {request.url}")
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "error": {
                "code": exc.error_code,
                "message": exc.message,
                "details": exc.details
            }
        }
    )

async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception on {request.url}: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "success": False,
            "error": {
                "code": "INTERNAL_SERVER_ERROR",
                "message": "An unexpected error occurred. Please try again later.",
                "details": {}
            }
        }
    )
