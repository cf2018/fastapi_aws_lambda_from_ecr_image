from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    app_env: str = Field(default="dev", alias="APP_ENV")
    stage: str = Field(default="dev", alias="STAGE")
    aws_region: str = Field(default="us-east-1", alias="AWS_REGION")
    lambda_name: str = Field(default="fastapi_aws_lambda", alias="LAMBDA_NAME")


@lru_cache
def get_settings() -> Settings:
    return Settings()
