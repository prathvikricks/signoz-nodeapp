## Grant Privileges to the Admin User
If you are able to log in as root, then manually create the admin user and grant privileges:

# Login as root:
```bash
docker exec -it mysql-school mysql -u root -p
```
# Enter the admin123 password.

## Grant access to the admin user:
Run the following SQL commands inside MySQL:


```bash
CREATE USER 'admin'@'%' IDENTIFIED BY 'admin123';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```
Exit and try logging in as admin:

```bash
docker exec -it mysql-school mysql -u admin -p
```
Enter admin123 when prompted.

## Restart the MySQL Container
If the issue persists, restart the container to ensure the changes are applied:

```bash
docker-compose down
docker-compose up -d
```
Now try logging in again using:

```bash
docker exec -it mysql-school mysql -u admin -p
```
