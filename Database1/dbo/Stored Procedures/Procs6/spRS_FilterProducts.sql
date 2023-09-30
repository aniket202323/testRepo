CREATE PROCEDURE [dbo].[spRS_FilterProducts]
@ErrorCode INT NULL OUTPUT, @ErrorMessage VARCHAR (1000) NULL OUTPUT, @Mode INT NULL, @ProductFamilyId INT NULL, @ProductGroupId INT NULL, @Mask NVARCHAR (100) NULL, @SearchBy INT NULL, @ProdIdList NVARCHAR (4000) NULL, @ProdFamilyIdList NVARCHAR (4000) NULL, @ProdGroupIdList NVARCHAR (4000) NULL, @SelectionType INT NULL, @FilterByDate INT NULL, @StartDate NVARCHAR (50) NULL, @StartTime NVARCHAR (50) NULL, @EndDate NVARCHAR (50) NULL, @EndTime NVARCHAR (50) NULL, @PUIdList NVARCHAR (4000) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


