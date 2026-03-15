# Fast API:
FastAPI is extremely popular for AI backends because:

• built for Python
• extremely fast
• automatic documentation
• strong typing
• simple JSON APIs

It’s used widely in:

LLM services
AI agents
ML inference servers
data APIs

# Pydantic
defines and validate data structures
basically you define the shape of incoming data and pydantic ensures its correct
so when someone sends a JSON to my API -> pydantic converts into a class object -> and then you can access fields like this: object.<field>

# model_dump()
model_dump() converts pydantic object into python dictionary -> as the function expects a python dictionary

# load_dotenv
loads the .env file and accesses the important keys

# http://127.0.0.1:8000/docs : 
This is great -> Fast API automatically generates OpenAI spec and Swagger UI -> helps in visualizing the endpoints.
Basically a built-in testing tool for our endpoints
An interactive API playground.

# routers
# services
# schemas
# agents
# ASGI server