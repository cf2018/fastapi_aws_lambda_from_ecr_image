from fastapi import APIRouter, Depends
from app.services.hello_service import HelloService

router = APIRouter()


def get_hello_service() -> HelloService:
    return HelloService()


@router.get("/", summary="Health check / hello world")
def read_root(service: HelloService = Depends(get_hello_service)):
    return {"message": service.say_hello()}
