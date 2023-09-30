CREATE VIEW [PR_System].[CustomDataTypeValue]
AS
SELECT
	[DataTypeId],
	[DataTypePhraseId]          AS [ValueId],
	[DataTypePhraseName]        AS [Value],
	[DataTypePhraseDescription] AS [Description],
	[SortOrder], 
	[Version]
FROM [dbo].QFDataTypePhrases