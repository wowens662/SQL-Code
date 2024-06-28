
/*
The source csv file is "Nashville Housing Data for Data Cleaning.csv" which
was found on github.  The dataset contains real estate data for the Nashville, TN
area that will be used for this project.
*/

SELECT *
FROM PortfolioProject..NashvilleHousing


--Standardize date Format for SaleDate field due to its datetime format
--Transform it 'yyyy-mm-dd', discarding the time element that is present.


SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject..NashvilleHousing


UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

--The conversion didn't materialize using this statement, 
--so we need an alternative method of creating a new column.

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)


SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM PortfolioProject..NashvilleHousing


---------------------------------------------------------------------------------------------------------------

--Populate Property Address data
--There are so many records where this field is null but
--is populated in other records.  I resorted to searching
--for records with same ParcelID where the PropertyAddress was
--populated as a reference point to fill those empty PropertyAddress
--fields.

SELECT *
FROM PortfolioProject..NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
    ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


UPDATE a  --Need to use alias for update statement involving a JOIN
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
    ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL





---------------------------------------------------------------------------------------------------------------

--Separating Address field into 2 individual columns (Address and City).


SELECT SUBSTRING(PropertyAddress, 1,CHARINDEX(',',PropertyAddress)-1) AS Address
       ,SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing
 

ALTER TABLE PortfolioProject..NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1,CHARINDEX(',',PropertyAddress)-1)



ALTER TABLE PortfolioProject..NashvilleHousing
Add PropertySplitCity Nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))


--Separating Owner Address field into 3 individual columns (Address,City, and State).
--Since the ParseName function is only useful for periods, we replace the commas with 
--periods before separating the string.
	
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'),3)
,PARSENAME(REPLACE(OwnerAddress,',','.'),2)
,PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM PortfolioProject..NashvilleHousing


ALTER TABLE PortfolioProject..NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE PortfolioProject..NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)


ALTER TABLE PortfolioProject..NashvilleHousing
Add OwnerSplitState Nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

	
---------------------------------------------------------------------------------------------------------------
	
--Changing 'Y' and 'N' to "Yes" and "No" in Sold as Vacant field.  The field
--currently contains four distinct values ('Y','N','Yes', and 'No'), so "Yes" or
--"No" should be the only two options to standardize the values.


SELECT DISTINCT(SoldAsVacant)
FROM
PortfolioProject..NashvilleHousing


SELECT SoldAsVacant, Count(*)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2 DESC


SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM PortfolioProject..NashvilleHousing
WHERE SoldAsVacant IN ('Y','N')


UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
                        WHEN SoldAsVacant = 'N' THEN 'No'
	                ELSE SoldAsVacant
	                END

---------------------------------------------------------------------------------------------------------------

	
--Remove Duplicates
--Note: It is not a standard practice to delete data;these records would be placed in a temp table as a precaution.


--Will need to partition records on fields that should be unique to each row
	
WITH ROWNUMCTE AS(
SELECT *,
   ROW_NUMBER() OVER (
   PARTITION BY ParcelID,
                PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference
		ORDER BY
		  UniqueID
		  ) row_num
FROM PortfolioProject..NashvilleHousing
--ORDER BY ParcelID
)


SELECT * 
FROM ROWNUMCTE
WHERE row_num > 1
ORDER BY PropertyAddress



DELETE  
FROM ROWNUMCTE
WHERE row_num > 1




---------------------------------------------------------------------------------------------------------------

--Delete Unused Columns (OwnerAddress, TaxDistrict, PropertyAddress)

SELECT *
FROM PortfolioProject..NashvilleHousing


ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress


ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN SaleDate
