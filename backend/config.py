from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Keycloak
    keycloak_url: str = "http://10.245.23.168:8080"
    keycloak_realm: str = "parqueadero"
    
    # Database
    database_url: str = "postgresql://root@10.245.23.52:26257/parqueadero?sslmode=disable"
    
    # API
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    debug: bool = True
    
    class Config:
        env_file = ".env"

settings = Settings()
