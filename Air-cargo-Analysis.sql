CREATE DATABASE AirCaroAnalysis;
USE aircaroanalysis;

/*2.	Write a query to create a route_details table using suitable data types for the fields, 
such as route_id, flight_num, origin_airport, destination_airport, aircraft_id, and distance_miles. 
Implement the check constraint for the flight number and unique constraint for the route_id fields. 
Also, make sure that the distance miles field is greater than 0. */

CREATE TABLE route_details(
route_id INT NOT NULL,
flight_num VARCHAR(10) NOT NULL,
origin_airport VARCHAR(3) NOT NULL,
destination_airport VARCHAR(3) NOT NULL,
aircraft_id INT NOT NULL,
distance_miles DECIMAL(10, 2) NOT NULL,

PRIMARY KEY (route_id),
UNIQUE (route_id),
CHECK (flight_num REGEXP '^[A-Za-z] {2, 3} [0-9] {3, 4}$'),
CHECK (distance_miles > 0)
);

SELECT * FROM route_details;

/*3.	Write a query to display all the passengers (customers) who have travelled
 in routes 01 to 25. Take data from the passengers_on_flights table.*/
 
 SELECT DISTINCT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.date_of_birth,
    c.gender FROM 
    passengers_on_flights p 
    JOIN customer c ON p.customer_id = c.customer_id 
    WHERE  p.route_id BETWEEN 1 AND 25
ORDER BY c.last_name, c.first_name;

/*4.	Write a query to identify the number of passengers and total revenue in bussiness class from the ticket_details table.*/

SELECT COUNT(DISTINCT customer_id) AS unique_passengers, 
SUM(no_of_tickets * Price_per_ticket) AS total_revenue 
FROM ticket_details WHERE class_id = 'Business';

/*5.Write a query to display the full name of the customer by extracting the first name and last name from the customer table.*/

SELECT concat(first_name, ' ', last_name) AS Full_Name FROM customer;

/*6. Write a query to extract the customers who have registered and booked a ticket.
 Use data from the customer and ticket_details tables.*/
 
 SELECT DISTINCT c.customer_id, c.first_name, c.last_name FROM customer c
WHERE c.customer_id IN (SELECT DISTINCT customer_id FROM ticket_details)
ORDER BY c.last_name, c.first_name;

/*7. Write a query to identify the customer’s first name and last name 
based on their customer ID and brand (Emirates) from the ticket_details table.*/

SELECT first_name, last_name FROM customer 
WHERE customer_id IN(SELECT DISTINCT customer_id FROM ticket_details WHERE brand = 'Emirates');

/*8. Write a query to identify the customers who have travelled by Economy Plus class using 
Group By and Having clause on the passengers_on_flights table. */

SELECT DISTINCT c.customer_id, c.first_name, c.last_name  FROM customer c 
JOIN passengers_on_flights p ON c.customer_id = p.customer_id
WHERE p.class_id = 'Economy Plus' 
GROUP BY c.customer_id, c.first_name, c.last_name;

USE aircaroanalysis;
SHOW TABLES;

/*9. Write a query to identify whether the revenue has crossed 10000 using the IF clause on the ticket_details table.*/

SELECT
	if(sum(no_of_tickets * Price_per_ticket) > 10000,
    'yes - Revenue exceeded 10,000',
    'No - Revenue below 10000') AS Revenue_Status,
    concat(Format(sum(no_of_tickets * Price_per_ticket), 2)) as total_revenue
    FROM ticket_details;

/*10. Write a query to create and grant access to a new user to perform operations on a database.*/

-- create new user

CREATE USER 'Sara@localhost' IDENTIFIED BY 'Newpass@123';

USE aircaroanalysis;
-- Grant access to new user 
GRANT ALL PRIVILEGES ON aircaroanalysis.* TO 'Sara'@'localhost';
SELECT User, Host FROM mysql.user;

/*11.Write a query to find the maximum ticket price for each class using window functions on the ticket_details table. */

SELECT *, MAX(Price_per_ticket) OVER(PARTITION BY class_id) AS Max_price_in_class
FROM ticket_details;

/*12. Write a query to extract the passengers whose route ID is 4 by improving the speed and performance 
of the passengers_on_flights table.*/

-- create index on route_id if it doesn't exist
CREATE INDEX idx_route_id ON passengers_on_flights(route_id);

-- extract the passener whose rout-id is 4

SELECT * FROM passengers_on_flights
WHERE route_id = '4';

/*13. For the route ID 4, write a query to view the execution plan of the passengers_on_flights table.*/

EXPLAIN SELECT * FROM passengers_on_flights
WHERE route_id = 4;

/*14.	Write a query to calculate the total price of all tickets booked by a customer 
across different aircraft IDs using rollup function. */

SELECT 
    customer_id,
    aircraft_id,
    SUM(no_of_tickets * Price_per_ticket) AS total_price
FROM 
    ticket_details
GROUP BY 
    customer_id, aircraft_id WITH ROLLUP;	

/*15. Write a query to create a view with only business class customers along with the brand of airlines. */

CREATE VIEW business_classView AS
SELECT customer_id, brand
FROM  ticket_details
WHERE class_id = 'Business';

SELECT * FROM business_classView;

/*16. Write a query to create a stored procedure to get the details of all passengers flying between 
 a range of routes defined in run time. Also, return an error message if the table doesn't exist.*/    
 
DELIMITER //
CREATE PROCEDURE check_route (
IN start_route_id INT, 
IN end_route_id INT
)
BEGIN 
DECLARE table_exists INT DEFAULT 0;

    -- Check if table exists
    
SELECT COUNT(*) INTO table_exists 
FROM information_schema.tables 
WHERE table_schema = DATABASE() 
AND table_name = 'passengers_on_flights';

    -- If table exists
    
    IF table_exists = 1 THEN 
    SELECT * FROM passengers_on_flights 
    WHERE route_id 
    BETWEEN start_route_id 
    AND end_route_id;
    ELSE SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Error: table passengers_on_flights does not exist.';
    END IF;
    
END //

DELIMITER ;

CALL check_route(1, 10);

/*17.	Write a query to create a stored procedure that extracts all the details
from the routes table where the travelled distance is more than 2000 miles.*/

DELIMITER //
CREATE PROCEDURE check_route1()
BEGIN
SELECT route_id, flight_num, aircraft_id, origin_airport, destination_airport, distance_miles
FROM routes WHERE distance_miles > 2000
ORDER BY distance_miles DESC;
END//
DELIMITER ;

CALL check_route1();

/*18.	Write a query to create a stored procedure that groups the distance travelled by each flight into three categories.
The categories are, short distance travel (SDT) for >=0 AND <= 2000 miles, 
intermediate distance travel (IDT) for >2000 AND <=6500, and long-distance travel (LDT) for >6500.*/

DELIMITER //
CREATE PROCEDURE CategorizeFlightDistances()
BEGIN
    SELECT route_id, flight_num, origin_airport, destination_airport, aircraft_id, distance_miles,
        CASE 
            WHEN distance_miles >= 0 AND distance_miles <= 2000 THEN 'SDT (Short Distance Travel)'
            WHEN distance_miles > 2000 AND distance_miles <= 6500 THEN 'IDT (Intermediate Distance Travel)'
            WHEN distance_miles > 6500 THEN 'LDT (Long Distance Travel)'
            ELSE 'Invalid Distance'
        END AS distance_category FROM routes ORDER BY distance_miles DESC;
END //
DELIMITER ;
CALL CategorizeFlightDistances();

/*19. Write a query to extract ticket purchase date, customer ID, class ID and specify if the complimentary 
services are provided for the specific class using a stored function in stored procedure on the ticket_details table. 
Condition: 
●	If the class is Business and Economy Plus, then complimentary services are given as Yes, else it is No */

-- Create the stored function

DELIMITER //
CREATE FUNCTION CheckComplimentaryServices(class VARCHAR(20)) 
RETURNS VARCHAR(3)
DETERMINISTIC
BEGIN
    DECLARE result VARCHAR(3);
    IF class IN ('Bussiness', 'Economy Plus') THEN
        SET result = 'Yes';
    ELSE
        SET result = 'No';
    END IF;
    RETURN result;
END //

DELIMITER ;

-- create the stored procedure that uses this function:

DELIMITER //
CREATE PROCEDURE GetTicketDetailsWithComplimentaryServices()
BEGIN
    SELECT 
        p_date AS purchase_date,
        customer_id,
        class_id,
        CheckComplimentaryServices(class_id) AS complimentary_services,
        brand AS airline,
        Price_per_ticket
    FROM 
        ticket_details
    ORDER BY 
        p_date DESC, customer_id;
END //
DELIMITER ;
-- To execute the procedure

CALL GetTicketDetailsWithComplimentaryServices();

/*20.Write a query to extract the first record of the customer whose last name 
ends with Scott using a cursor from the customer table.*/

DELIMITER //
CREATE PROCEDURE GetFirstScot()
BEGIN
    DECLARE cust_id INT;
    DECLARE f_name VARCHAR(50);
    DECLARE l_name VARCHAR(50);
    DECLARE dob DATE DEFAULT NULL;
    DECLARE gend CHAR(1);
    -- Get the first Scott customer directly
    SELECT customer_id, first_name, last_name, 
           CAST(date_of_birth AS DATE), gender
    INTO cust_id, f_name, l_name, dob, gend
    FROM customer
    WHERE last_name LIKE '%Scott'
    ORDER BY customer_id
    LIMIT 1;
    
    -- Return the result
    SELECT cust_id AS customer_id, f_name AS first_name, 
           l_name AS last_name, dob AS date_of_birth, gend AS gender;
END //

DELIMITER ;

CALL GetFirstScot();

DESCRIBE customer;

SET SQL_SAFE_UPDATES = 0;

UPDATE customer
SET date_of_birth = STR_TO_DATE(date_of_birth, '%d-%m-%Y');

ALTER TABLE customer
MODIFY COLUMN date_of_birth DATE;

/*Top 5 Revenue Generating Routes*/
SELECT route_id,
       SUM(no_of_tickets * price_per_ticket) AS total_revenue
FROM ticket_details
GROUP BY route_id
ORDER BY total_revenue DESC
LIMIT 5;

/*Revenue by Class Contribution %*/
SELECT class_id,
       SUM(no_of_tickets * price_per_ticket) AS revenue,
       ROUND(
         SUM(no_of_tickets * price_per_ticket) /
         (SELECT SUM(no_of_tickets * price_per_ticket) FROM ticket_details) * 100, 2
       ) AS revenue_percentage
FROM ticket_details
GROUP BY class_id;

/*Monthly Revenue Trend*/
SELECT DATE_FORMAT(p_date, '%Y-%m') AS month,
       SUM(no_of_tickets * price_per_ticket) AS monthly_revenue
FROM ticket_details
GROUP BY month
ORDER BY month;