****For Running this application****

**First edit the .env with your actual Database cred's**
```bash
DB_HOST=jsbjbsdvs
DB_USER=admin
DB_PASSWORD=admin123
DB_NAME=schooldb
REDIS_URL=redis://redis:6379
```

**The schema for the database should be**
```bash
CREATE TABLE students (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  age INT NOT NULL,
  class VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```


**After make sure these are in place do docker-compose up -d --build**
```bash
docker-compose up -d --build
```

Preview be
<img width="1470" alt="Screenshot 2025-02-21 at 10 27 56 AM" src="https://github.com/user-attachments/assets/c994d7fe-3835-4d9e-9985-78144a1cab64"/>
<img width="1470" alt="Screenshot 2025-02-21 at 10 29 44 AM" src="https://github.com/user-attachments/assets/bd0a05ab-9921-4188-bf5c-6095df1e738c"/>
