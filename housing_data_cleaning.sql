USE portfolioproject;
SELECT * FROM nashville_housing;

-- CHANGING "SaleDate" COLUMN TO ACCEPTABLE MYSQL TEXT FORMAT BEFORE CONVERSION TO "date" TYPE
UPDATE nashville_housing
set SaleDate = str_to_date(SaleDate,"%M %d, %Y");  -- note: used 'M' because the date was in text i.e. April instead of 4


-- POPULATING THE "PropertyAddress" COLUMN 
-- Shows that there are empty strings under the PropertyAddress column
SELECT * FROM nashville_housing
WHERE PropertyAddress = '';
-- Shows that there's a relationship between ParcelID and PropertyAddress; Thers's functional dependency.
SELECT a.ParcelID,a.PropertyAddress, b.ParcelID,b.PropertyAddress
FROM nashville_housing a
JOIN nashville_housing b
	on a.ParcelID = b.ParcelID
    AND a.UniqueID <> a.UniqueID  -- matches rows with differing UniqueID but with the same ParcelID 
WHERE a.PropertyAddress = '';
-- Now let's replace the empty PropertyAddress column using the joined table
UPDATE nashville_housing a
JOIN nashville_housing b
	on a.ParcelID = b.ParcelID
    AND a.UniqueID <> a.UniqueID
SET a.PropertyAddress = CASE
	WHEN a.PropertyAddress = '' THEN a.PropertyAddress =b.PropertyAddress 
END;


-- BREAKING UP THE PropertAddress COLUMN INTO INDIVIDUAL COLUMNS
SELECT PropertyAddress FROM nashville_housing; -- There's a comma delimiter between street address and the city name.
-- Adding 2 new columns derived from splitting the "PropertyAddress" column
ALTER TABLE nashville_housing
ADD StreetName nvarchar(255);
UPDATE nashville_housing
SET StreetName = substring_index(PropertyAddress, ', ',1);

ALTER TABLE nashville_housing
ADD CityName nvarchar(255);
UPDATE nashville_housing
SET CityName = substring_index(PropertyAddress, ', ',-1);
-- Adding 3 new columns derived from splitting the "PropertyAddress" column. 
ALTER TABLE nashville_housing
ADD OwnerStreetName nvarchar(255);
UPDATE nashville_housing
SET OwnerStreetName = substring_index(OwnerAddress, ', ',1);

ALTER TABLE nashville_housing
ADD OwnerCityName nvarchar(255);
UPDATE nashville_housing
SET OwnerCityName = substring_index(substring_index(OwnerAddress, ', ',2),', ',-1);

ALTER TABLE nashville_housing
ADD OwnerStateName nvarchar(255);
UPDATE nashville_housing
SET OwnerStateName = substring_index(OwnerAddress, ', ',-1);


-- CLEAN UP "SoldAsVacant" COLUMN -> CHANGE "Y" & "N" TO "YES" & "NO"
-- Showing the discrepancy in "SoldAsVacant" column
SELECT DISTINCT(SoldAsVacant) as Status, COUNT(SoldAsVacant) as StatusCount
FROM nashville_housing
GROUP BY Status;
-- Now we conduct the change
UPDATE nashville_housing
SET SoldAsVacant = CASE
	WHEN SoldAsVacant = "Y" THEN "Yes"
    WHEN SoldAsVacant = "N" THEN "No"
    ELSE SoldAsVacant
    END;
    
-- REMOVING DUPLICATES
-- by assigning row numbers over partitions based on several columns. The partition helps to group rows that are identical based on the columns we select. The row number tells us if there are duplicates (>1 means duplicate).
WITH RowNumCTE as(
SELECT * ,
	ROW_NUMBER() OVER (
    PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
    ORDER BY UniqueID) as RowNum
FROM nashville_housing)
SELECT *
FROM RowNumCTE
WHERE RowNum >1;  -- Used to check if duplicate still there. NOTE:in MySQL, we can't delete data from CTEs because it is read-only. so need to join to original table and delete from there. 

WITH RowNumCTE as(
SELECT * ,
	ROW_NUMBER() OVER (
    PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
    ORDER BY UniqueID) as RowNum
FROM nashville_housing)
DELETE a FROM nashville_housing a 
INNER JOIN RowNumCTE b on a.UniqueID = b.UniqueID 
WHERE RowNum >1;  -- most challenging part of the project

-- DELETING UNUSED COLUMNS (Best practice: don't directly alter raw data, we doing for practice purposes)
ALTER TABLE nashville_housing
DROP COLUMN OwnerAddress, 
DROP COLUMN PropertyAddress,
DROP COLUMN TaxDIstrict;

select * from nashville_housing;
