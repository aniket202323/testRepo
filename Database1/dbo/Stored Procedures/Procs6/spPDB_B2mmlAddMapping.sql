CREATE PROCEDURE dbo.spPDB_B2mmlAddMapping
(
 	 @mapping ntext,
 	 @xpathpram ntext,
 	 @tableMap ntext
)
AS
    DECLARE @hDoc int 	  	 -- xml doc
    DECLARE @hDoc2 int    
 	 DECLARE @hDoc3 int 	 
    -- parse xml doc
    EXEC sp_xml_preparedocument @hDoc output, @mapping
    EXEC sp_xml_preparedocument @hDoc2 output, @xpathpram
 	 EXEC sp_xml_preparedocument @hDoc3 output, @tableMap
    SET NOCOUNT ON
    DECLARE @CurrentError int
    -- start transaction, updating three tables
    BEGIN TRANSACTION
 	 
 	 -- perform deletes first
 	 DELETE FROM PdbProcsDS_R_PdbParmXpathDS
 	 FROM OPENXML(@hDoc, '/NewDataSet/Table')
 	 WITH PdbProcsDS_R_PdbParmXpathDS Mapping
 	 WHERE PdbProcsDS_R_PdbParmXpathDS.ElementId = Mapping.ElementId
 	 
 	 -- check for error
    SELECT @CurrentError = @@Error
 	 IF @CurrentError != 0 BEGIN
    	  	 GOTO ERROR_HANDLER
    END
 	 DELETE FROM MappedxsdSchemaElements_R_PdbProcsDS
 	 FROM OPENXML(@hDoc, '/NewDataSet/Table')
 	 WITH MappedxsdSchemaElements_R_PdbProcsDS Mapping
 	 WHERE MappedxsdSchemaElements_R_PdbProcsDS.ElementId = Mapping.ElementId
 	 -- check for error
    SELECT @CurrentError = @@Error
 	 IF @CurrentError != 0 BEGIN
    	  	 GOTO ERROR_HANDLER
    END
 	 DELETE FROM MappedxsdSchemaElements_R_PdbProcParmDS
 	 FROM OPENXML(@hDoc, '/NewDataSet/Table')
 	 WITH MappedxsdSchemaElements_R_PdbProcParmDS Mapping
 	 WHERE MappedxsdSchemaElements_R_PdbProcParmDS.ElementId = Mapping.ElementId
 	 -- check for error
    SELECT @CurrentError = @@Error
 	 IF @CurrentError != 0 BEGIN
    	  	 GOTO ERROR_HANDLER
    END
 	 DELETE FROM MappedxsdSchemaElements_R_ConstantsDS
 	 FROM OPENXML(@hDoc, '/NewDataSet/Table')
 	 WITH MappedxsdSchemaElements_R_ConstantsDS Mapping
 	 WHERE MappedxsdSchemaElements_R_ConstantsDS.ElementId = Mapping.ElementId
 	 -- check for error
    SELECT @CurrentError = @@Error
 	 IF @CurrentError != 0 BEGIN
    	  	 GOTO ERROR_HANDLER
    END
 	 DELETE FROM MappedxsdSchemaElements_R_PdbTableColumnDS
 	 FROM OPENXML(@hDoc, '/NewDataSet/Table')
 	 WITH MappedxsdSchemaElements_R_PdbTableColumnDS Mapping
 	 WHERE MappedxsdSchemaElements_R_PdbTableColumnDS.ElementId = Mapping.ElementId
 	 -- check for error
    SELECT @CurrentError = @@Error
 	 IF @CurrentError != 0 BEGIN
    	  	 GOTO ERROR_HANDLER
    END
 	 
 	 DELETE FROM Mapped_xsdSchemaElements
 	 FROM OPENXML(@hDoc, '/NewDataSet/Table')
 	 WITH Mapped_xsdSchemaElements Mapping
 	 WHERE Mapped_xsdSchemaElements.ElementId = Mapping.ElementId
 	 -- check for error
    SELECT @CurrentError = @@Error
 	 IF @CurrentError != 0 BEGIN
    	  	 GOTO ERROR_HANDLER
    END
 	  	 
    -- add Mapped Schema elements
    INSERT INTO  Mapped_xsdSchemaElements
     	 (ElementId, MappingTypeId)
 	 SELECT ElementId, MappingTypeId
    FROM OpenXML(@hDoc, '/NewDataSet/Table[@MappingTypeId>0]')
    WITH  (ElementId bigint,
 	        MappingTypeId bigint)
 	 
 	 -- check for error
    SELECT @CurrentError = @@Error
 	 IF @CurrentError != 0 BEGIN
    	  	 GOTO ERROR_HANDLER
    END
 	     
    -- add Tables, Columns
    INSERT INTO  MappedxsdSchemaElements_R_PdbTableColumnDS
     	 (ElementId, TableName, ColumnName)
 	 SELECT ElementId, TableName, ColumnName
    FROM OpenXML(@hDoc3, '/NewDataSet/Table')
    WITH  (ElementId bigint,
           TableName nvarchar(50),
 	        ColumnName nvarchar(50))
 	 
 	 -- check for error
    SELECT @CurrentError = @@Error
 	 IF @CurrentError != 0 BEGIN
    	  	 GOTO ERROR_HANDLER
    END
 	 
    -- add Procs, Params
    INSERT INTO  MappedxsdSchemaElements_R_PdbProcParmDS
     	 (ElementId, ProcName, ParamName)
 	 SELECT ElementId, ProcName, ParamName
    FROM OpenXML(@hDoc, '/NewDataSet/Table[@MappingTypeId=2]')
    WITH (ElementId bigint,
          ProcName nvarchar(128),
 	       ParamName nvarchar(128))
 	 
 	 -- check for error
    SELECT @CurrentError = @@Error
 	 IF @CurrentError != 0 BEGIN
    	  	 GOTO ERROR_HANDLER
    END
 	 -- add Constants
    INSERT INTO  MappedxsdSchemaElements_R_ConstantsDS
     	 (ElementId, Constant)
 	 SELECT ElementId, Constant 
    FROM OpenXML(@hDoc, '/NewDataSet/Table[@MappingTypeId=3]')
    WITH (ElementId bigint,
 	       Constant sql_variant)
 	 
 	 -- check for error
    SELECT @CurrentError = @@Error
 	 IF @CurrentError != 0 BEGIN
    	  	 GOTO ERROR_HANDLER
    END
    -- add Procs, Xpath
    INSERT INTO MappedxsdSchemaElements_R_PdbProcsDS
     	 (ElementId, ProcName, sequence_num)
 	 SELECT ElementId, xPathProc, sequence_num
    FROM OpenXML(@hDoc, '/NewDataSet/Table[@MappingTypeId=4]')
    WITH (ElementId bigint,
          xPathProc nvarchar(128),
 	       sequence_num int)
 	 
 	 -- check for error
    SELECT @CurrentError = @@Error
 	 IF @CurrentError != 0 BEGIN
    	  	 GOTO ERROR_HANDLER
    END
    -- add Params, Xpath
    INSERT INTO PdbProcsDS_R_PdbParmXpathDS
     	 (ElementId, ParamName, xPathExpr)
 	 SELECT ElementId, ParamName, xPathExpr
    FROM OpenXML(@hDoc2, '/NewDataSet/Table')
    WITH (ElementId bigint,
          ParamName nvarchar(128),
 	    	   xPathExpr nVarChar(1000))
 	 
 	 -- check for error
    SELECT @CurrentError = @@Error
 	 IF @CurrentError != 0 BEGIN
    	  	 GOTO ERROR_HANDLER
    END
    -- end of transaction
    COMMIT TRANSACTION
    SET NOCOUNT OFF
    -- done with xml doc
    EXEC sp_xml_removedocument @hDoc
    EXEC sp_xml_removedocument @hDoc2
 	 EXEC sp_xml_removedocument @hDoc3
    RETURN 1
    ERROR_HANDLER:
        ROLLBACK TRANSACTION
        SET NOCOUNT OFF    
        RETURN 0    
