SELECT * FROM inventory.temp;

SELECT DISTINCT VARIANTS FROM inventory.temp;

SELECT DISTINCT STAT FROM inventory.temp;

-- Add the new column `status_2` to the table
ALTER TABLE inventory.temp
ADD COLUMN status_2 TEXT;

-- Update `status_2` based on the conditions
UPDATE inventory.temp
SET status_2 = CASE
    WHEN VARIANTS = 'REGULAR' AND QTY > 0 AND STAT = 'Live' THEN 'active'
    WHEN VARIANTS <> 'REGULAR' AND QTY > 1 AND STAT = 'Live' THEN 'active'
    ELSE 'inactive'
END;

SELECT * FROM inventory.temp
WHERE STAT = "PENDING PHOTO-for reshoot";

SELECT * FROM inventory.temp
WHERE VARIANTS = "REGULAR";

SELECT *
FROM inventory.temp;
