create procedure dbo.spPDB_InsertIntoxsdSchemaElements @SchemaName nvarchar(50), @ParentId bigint, @ElementName nvarchar(50), @ElementType bigint
as
INSERT INTO xsdSchemaElements ([SchemaName],[ParentElementId],[ElementName],[ElementType]) VALUES (@SchemaName,@ParentId,@ElementName, @ElementType)
SELECT scope_identity() 	 
