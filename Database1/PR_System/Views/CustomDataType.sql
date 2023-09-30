CREATE VIEW [PR_System].[CustomDataType]
AS
SELECT
	[DataTypeId],
	[DataTypeName]        AS [Name],
	[DataTypeDescription] AS [Description],
	[Version]
FROM [dbo].QFDataTypes
WHERE IsCustomDataType = 1