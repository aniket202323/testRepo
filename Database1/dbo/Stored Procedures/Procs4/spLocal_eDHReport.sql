CREATE PROCEDURE [dbo].[spLocal_eDHReport]
@DepartmentId NVARCHAR (MAX) NULL, @ProdLineId NVARCHAR (MAX) NULL, @ProdUnitId NVARCHAR (MAX) NULL, @PUGroupId NVARCHAR (MAX) NULL, @Lvl5SubassemblyId NVARCHAR (MAX) NULL, @Lvl6SubassemblyId NVARCHAR (MAX) NULL, @Lvl7SubassemblyId NVARCHAR (MAX) NULL, @TypeList NVARCHAR (255) NULL, @ComponentList NVARCHAR (255) NULL, @HowFoundList NVARCHAR (255) NULL, @FoundByList NVARCHAR (255) NULL, @FixedByList NVARCHAR (255) NULL, @PriorityList NVARCHAR (255) NULL, @StartTime DATETIME NULL, @EndTime DATETIME NULL, @FLCodeList NVARCHAR (MAX) NULL, @TeamList NVARCHAR (255) NULL, @LangCode NVARCHAR (10) NULL, @KPI NVARCHAR (50) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


