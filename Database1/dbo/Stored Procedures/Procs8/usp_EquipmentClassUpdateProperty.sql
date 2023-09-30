/* PROCEDURE: [usp_EquipmentClassUpdateProperty] */


/* SYNOPSIS
 * Update a property on an EquipmentClass.
 * The algorithm is as follows:
 *  - If the DefinedBy value has changed, perform a delete and add of the property, as the subproperties will completely change.
 *  - Otherwise, update as follows:
 *		- Update record in StructuredTypeProperty table.
 *		- If the datatype of the Property is 14 (Class) exec usp_EquipmentClassRenamePropertyOfTypeClass (details can't change for class properties, so it's just a rename)
 *		- Otherwise, exec usp_EquipmentClassUpdatePropertyOfTypeScalar
 *		- Update EquipmentClass to increment Version
 * END SYNOPSIS */

 /* HISTORY
 * Created Nov. 27 by Ryan Berry
 * END HISTORY */
CREATE PROCEDURE [dbo].[usp_EquipmentClassUpdateProperty]
/* PARAMETERS */
@p_EquipmentClassId          UNIQUEIDENTIFIER, -- GUID of the EquipmentCLass
@p_PropertyName              NVARCHAR(200),    -- The original property name
@p_UpdatedPropertyName       NVARCHAR(200),    -- The updated property name
@p_Description               NVARCHAR(255),    -- The property description
@p_DescriptionOverridden     BIT,			   -- Is the description overridden by this class
@p_DataType                  INT,              -- The property datatype
@p_UnitOfMeasure             NVARCHAR(255),    -- The property UnitOfMeasure
@p_UnitOfMeasureOverridden   BIT,			   -- Is the UoM overridden by this clas
@p_Value                     SQL_VARIANT,      -- The property default value
@p_ValueOverridden           BIT,				-- Is the value overridden by this class
@p_DefinedBy                 UNIQUEIDENTIFIER = null, -- for the StructuredTypeProperty table
@p_UpdateDetailsOnly		 BIT  = 0,         -- if 1, we are only updating the description, value, or UnitOfMeasure (NOT the type or name)
@debug                       BIT = 0,          -- if 1, print debug statements
@test                        BIT = 0           -- if 1, do not actually modify any records
/* END PARAMETERS */
AS
   DECLARE
       @c_DataTypeClass INT,
   	   @i               INT,
       @iMax            INT,
	   @v_TimeStamp     DATETIME,
	   @v_EquipmentId   UNIQUEIDENTIFIER,
	   @v_EquipmentClassName NVARCHAR(200),
	   @v_ProcName      VARCHAR(100),
	   @v_TrxName       VARCHAR(32),
	   @trancount       INT,
	   @v_start_time    DATETIME,
	   @v_end_time      DATETIME,
	   @v_RecordsUpdated  INT,
	   @v_PropertiesUpdated INT,
	   @v_OriginalDefinedBy UNIQUEIDENTIFIER,
	   @c_GUIDEmpty UNIQUEIDENTIFIER

   SET @v_ProcName =  'L' + CONVERT(VARCHAR(2),@@NESTLEVEL) + ': usp_EquipmentClassUpdateProperty: '
   SET @v_TrxName = 'EquipClassUpdateProperty'
   SET @v_start_time = CURRENT_TIMESTAMP
   SET @v_RecordsUpdated = 0
   SET @v_PropertiesUpdated = 0
   PRINT ' '
   PRINT @v_ProcName + '  Start Time: ' + CONVERT(VARCHAR(23),@v_start_time)
   IF (@debug = 1)
   BEGIN
      PRINT ' '
      PRINT @v_ProcName + 'Parameters:'
      PRINT @v_ProcName + '  EquipmentClassId = ' + CONVERT(VARCHAR(36),@p_EquipmentClassId)
      PRINT @v_ProcName + '  PropertyName     = ' + @p_PropertyName
	  PRINT @v_ProcName + '  UpdatedPropertyName     = ' + @p_UpdatedPropertyName
	  PRINT @v_ProcName + '  p_Description   = ' + @p_Description
	  PRINT @v_ProcName + '  p_DescriptionOverriden   = ' + CONVERT(VARCHAR(5),@p_DescriptionOverridden)
	  PRINT @v_ProcName + '  p_DataType = ' + CONVERT(VARCHAR(36),@p_DataType)
      PRINT @v_ProcName + '  p_UnitOfMeasure = ' + @p_UnitOfMeasure
      PRINT @v_ProcName + '  p_UnitOfMeasureOverridden = ' + CONVERT(VARCHAR(5),@p_UnitOfMeasureOverridden)
      PRINT @v_ProcName + '  p_Value         = ' + CONVERT(VARCHAR(255),@p_Value)
      PRINT @v_ProcName + '  p_ValueOverridden         = ' + CONVERT(VARCHAR(5),@p_ValueOverridden)
      PRINT @v_ProcName + '  p_DefinedBy = ' +   CONVERT(VARCHAR(36),@p_DefinedBy)
	  PRINT @v_ProcName + '  p_UpdateDetailsOnly     = ' + CONVERT(VARCHAR(5),@p_UpdateDetailsOnly)
      PRINT @v_ProcName + 'End Parameters'
      PRINT ' ' 
   END

-- The Class DataType indicator value is 14 
   SET @c_DataTypeClass = 14

	SET @c_GUIDEmpty = '00000000-0000-0000-0000-000000000000'

-- initialize the timestamp
   SET @v_TimeStamp = (SELECT CURRENT_TIMESTAMP)

   SET NOCOUNT ON
   SET @trancount = @@trancount
   BEGIN try
      IF @trancount = 0
      BEGIN
         IF (@debug = 1) PRINT @v_ProcName + 'BEGIN TRANSACTION'
         BEGIN TRANSACTION
      END
      ELSE
      BEGIN
         IF (@debug = 1) PRINT @v_ProcName + 'SAVE TRANSACTION ' + @v_TrxName
	 SAVE TRANSACTION @v_ProcName
      END

-- Get the EquipmentClassName
      SET @v_EquipmentClassName = (SELECT EquipmentClassName
                                     FROM EquipmentClass
                                    WHERE Id = @p_EquipmentClassId)

-- Verify that we have a valid EquipmentClassName. 
      IF (@v_EquipmentClassName IS NULL)
      BEGIN
          RAISERROR ('50101: Equipment Class not found.', 11, 1)
          RETURN
      END 
     
      IF (@debug = 1)
         PRINT 'EquipmentClassName = ' + @v_EquipmentClassName

		SELECT @v_OriginalDefinedBy = DefinedBy FROM StructuredTypeProperty WHERE Name = @p_PropertyName AND TypeOwnerNamespace = N'Equipment' AND TypeOwnerName = @v_EquipmentClassName
		PRINT  @v_OriginalDefinedBy

-- If the defining type of the propety (e.g. from one class to another), just delete and re-add the property.
	IF (@v_OriginalDefinedBy != ISNULL(@p_DefinedBy, @c_GUIDEmpty))
	BEGIN
		IF (@debug = 1) PRINT 'DefinedBy changed from ' + CONVERT(VARCHAR(36),@v_OriginalDefinedBy) + ' to ' + CONVERT(VARCHAR(36),@p_DefinedBy)

		IF (@debug = 1) PRINT 'EXEC usp_EquipmentClassDeleteProperty ' + CONVERT(VARCHAR(36),@p_EquipmentClassId) + ', ' +  @p_PropertyName

		EXEC usp_EquipmentClassDeleteProperty
			@p_EquipmentClassId,
			@p_PropertyName,
			@debug,
			@test 

		IF (@debug = 1) PRINT 'EXEC usp_EquipmentClassAddProperty ' + CONVERT(VARCHAR(36),@p_EquipmentClassId) + ', ' +  @p_PropertyName

        EXEC usp_EquipmentClassAddProperty
			@p_EquipmentClassId,
			@p_PropertyName,
			@p_Description,
			@p_DataType,
			@p_UnitOfMeasure,
 			@p_Value,
			@p_DefinedBy,
			@debug,
 			@test,
			@v_PropertiesUpdated OUTPUT

		SET @v_RecordsUpdated = @v_PropertiesUpdated
	END

	ELSE
	BEGIN

		-- First, update record in StructuredTypeProperty table

		IF (@debug = 1)
			PRINT 'UPDATE StructuredTypeProperty WHERE Name = ''' + @p_PropertyName + ''' AND TypeOwnerName = ''' + @v_EquipmentClassName + ''')'

		IF (@p_UpdateDetailsOnly = 0 and @test = 0) 
		BEGIN
			UPDATE dbo.StructuredTypeProperty SET
			Name = @p_UpdatedPropertyName,
			DefinedBy = ISNULL(@p_DefinedBy, @c_GUIDEmpty),
			DataType = @p_DataType,
			LastBuiltName = @p_PropertyName,
			LastBuiltDefinedBy = ISNULL(@p_DefinedBy, @c_GUIDEmpty),
			Version = Version + 1
			WHERE Name = @p_PropertyName AND TypeOwnerNamespace = N'Equipment' AND TypeOwnerName = @v_EquipmentClassName
		END
	  	

		-- Call the appropriate update procedure based on the property's DataType   
		IF (@p_DataType = @c_DataTypeClass)
		BEGIN
			-- For a class property, the only thing we can update is the Name or Type. Type is handled by add/delete above. So just call the rename procedure.
			IF (@debug = 1) PRINT 'EXEC usp_EquipmentClassRenamePropertyOfTypeClass ''' + @v_EquipmentClassName + ''',''' + @p_PropertyName + ''',''' + @p_UpdatedPropertyName
			IF (@test = 0)
			EXEC usp_EquipmentClassRenamePropertyOfTypeClass
				@v_EquipmentClassName,
				@p_EquipmentClassId,
				@p_PropertyName,
				@p_UpdatedPropertyName,
				@debug,
				@v_PropertiesUpdated OUTPUT
		END
		ELSE
		BEGIN
			IF (@debug = 1) PRINT 'EXEC usp_EquipmentClassUpdatePropertyOfTypeScalar ''' + @v_EquipmentClassName + ''',''' + @p_PropertyName + ''''
				EXEC usp_EquipmentClassUpdatePropertyOfTypeScalar
					@v_EquipmentClassName,
					@p_PropertyName,
					@p_UpdatedPropertyName,
					@p_Description,
					@p_DescriptionOverridden,
   					@p_DataType,
					@p_UnitOfMeasure,
					@p_UnitOfMeasureOverridden,
   					@p_Value,
					@p_ValueOverridden,
					0, -- not a nested property
   					@debug,
   					@test,
					@v_PropertiesUpdated OUTPUT
		END

		-- Update EquipmentClass record to bump the version
		IF (@debug = 1)
		BEGIN
			PRINT 'UPDATE EquipmentClass '
			PRINT '    SET Version = (SELECT MAX(Version)+1'
			PRINT '                     FROM EquipmentClass)'
			PRINT '                    WHERE EquipmentClassName = ''' + @v_EquipmentClassName + ''')'
			PRINT '  WHERE EquipmentClassName = ''' + @v_EquipmentClassName + ''''
		END
		IF (@test = 0)
			UPDATE dbo.EquipmentClass 
				SET Version = (SELECT MAX(Version)+1 
							  FROM EquipmentClass 
							  WHERE EquipmentClassName = @v_EquipmentClassName)
				WHERE EquipmentClassName = @v_EquipmentClassName

	END
      
	IF (@debug = 1) PRINT @v_ProcName + 'Trancount = ' + convert(varchar(5),@trancount)
	IF (@trancount = 0)
	BEGIN
		IF (@debug = 1) PRINT @v_ProcName + 'Committing ...'
			COMMIT
	END

	SET @v_RecordsUpdated = @v_RecordsUpdated + @v_PropertiesUpdated
	SET @v_end_time = CURRENT_TIMESTAMP

-- done, print how many records were updated by this routine
	PRINT @v_ProcName + 'Records Updated: ' + CONVERT(VARCHAR(10),@v_RecordsUpdated) + 
      	    		  	   ' in ' +  CONVERT(VARCHAR(8),DATEDIFF(ms,@v_start_time,@v_end_time)) + ' ms'
	END try
	BEGIN catch
      DECLARE @error   INT, 
              @message VARCHAR(4000),
 	      @xstate  INT
      SELECT @error   = ERROR_NUMBER(),
             @message = ERROR_MESSAGE(),
             @xstate  = XACT_STATE()
      IF (@xstate = -1)
      BEGIN
         IF (@debug = 1) PRINT @v_ProcName + 'ROLLBACK'
		ROLLBACK
      END
      IF (@xstate = 1 AND @trancount = 0)
      BEGIN
         IF (@debug = 1) PRINT @v_ProcName + 'ROLLBACK'
 		ROLLBACK
      END
      IF (@xstate = 1 AND @trancount > 0)
      BEGIN
         IF (@debug = 1) PRINT @v_ProcName + 'ROLLBACK ' + @v_TrxName
 		ROLLBACK TRANSACTION @v_TrxName
      END;
/* SQL Server 2012 only
      THROW
*/
      RAISERROR('%s: %d: %s',16,1, @v_ProcName, @error, @message)
   END catch