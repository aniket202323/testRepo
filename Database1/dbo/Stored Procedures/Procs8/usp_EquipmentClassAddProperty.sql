/* PROCEDURE: usp_EquipmentClassAddProperty */

/* SYNOPSIS
 * Add a property to EquipmentClass.
 * The algorithm is as follows:
 * - Add record to StructuredTypeProperty table.
 * - If the datatype of the Property is 14 (Class) exec
 *       usp_EquipmentClassAddPropertyOfTypeClass 
 *   Otherwise, exec
 *       usp_EquipmentClassAddPropertyOfTypeScalar
 * - Update EquipmentClass to increment Version
 * END SYNOPSIS */

/* NOTES
 * END NOTES */

/* HISTORY
 * November 27, 2015 by R Berry: return count of records added.
 * BugFix_ Jun 01, 2013 by ll: check for valid EquipmentClassId
 * BugFix_ May 03, 2013 by ll: fix length of transaction names
 * IncrDev May 01, 2013 by ll: replace table variables with temporary tables
 * IncrDev May 01, 2013 by ll: add timing and record count metrics
 * BugFix_ Apr 12, 2013 by ll: THROW is a SQLServer 2012 construct only, replaced with RAISERROR
 * Created Mar 26, 2013 by ll:
 * END HISTORY */

CREATE PROCEDURE [dbo].[usp_EquipmentClassAddProperty]
/* PARAMETERS */
@p_EquipmentClassId          UNIQUEIDENTIFIER, -- GUID of the EquipmentCLass
@p_PropertyName              NVARCHAR(200),    -- The property name
@p_Description               NVARCHAR(255),    -- The property description
@p_DataType                  INT,              -- The property datatype
@p_UnitOfMeasure             NVARCHAR(255),    -- The property UnitOfMeasure
@p_Value                     SQL_VARIANT,      -- The property default value
@p_DefinedBy                 UNIQUEIDENTIFIER, -- for the StructuredTypeProperty table
@debug                       BIT = 0,          -- if 1, print debug statements
@test                        BIT = 0 ,         -- if 1, do not actually add any records
@ReturnRecordsAdded          INT OUTPUT			-- return the number of records added by this call
/* END PARAMETERS */
AS
   DECLARE @c_DataTypeClass INT,
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
	   @v_RecordsAdded  INT,
	   @v_PropertiesAdded INT,
	   @c_GUIDEmpty UNIQUEIDENTIFIER

   SET @v_ProcName =  'L' + CONVERT(VARCHAR(2),@@NESTLEVEL) + ': usp_EquipmentClassAddProperty: '
   SET @v_TrxName = 'EquipClassAddProperty'
   SET @v_start_time = CURRENT_TIMESTAMP
   SET @v_RecordsAdded = 0
   SET @v_PropertiesAdded = 0
   PRINT ' '
   PRINT @v_ProcName + '  Start Time: ' + CONVERT(VARCHAR(23),@v_start_time)
   IF (@debug = 1)
   BEGIN
      PRINT ' '
      PRINT @v_ProcName + 'Parameters:'
      PRINT @v_ProcName + '  EquipmentClassId = ' + CONVERT(VARCHAR(36),@p_EquipmentClassId)
      PRINT @v_ProcName + '  PropertyName     = ' + @p_PropertyName
      PRINT @v_ProcName + 'End Parameters'
      PRINT ' ' 
   END

-- The Class DataType indicator value is 14 

/* DEVELOPER_ATTENTION: This is dependant on the value of this DataType in the C# method. */
/* DOC: The datatype is from the SupportedTypes Array in the
 *      Proficy.Platform.Core.ProficySystem.Types.SystemDataTypes class.
 *      The SystemDataTypes.GetDataTypeId(newProperty.DataType)
 *      returns an integer value used as the dataType parameter which is used
 *      in these stored procedures.
 */
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

-- Insert record into StructuredTypeProperty table
      IF (@debug = 1)
         PRINT 'INSERT INTO StructuredTypeProperty (''' + @p_PropertyName + ''',''' + CONVERT(VARCHAR(36),@p_DefinedBy) + ''',''' 
	       	      + @v_EquipmentClassName + ''')'
      IF (@test = 0)
      INSERT INTO StructuredTypeProperty (
         Name,
         DefinedBy,
         DataType,
         LastBuiltName,
         LastBuiltDefinedBy,
         Version,
         TypeOwnerNamespace,
         TypeOwnerName)
      VALUES (
         @p_PropertyName,
         ISNULL(@p_DefinedBy, @c_GUIDEmpty),
         @p_DataType,
         @p_PropertyName,
         ISNULL(@p_DefinedBy, @c_GUIDEmpty),
         1,			-- version is always 1 when adding a new property
         N'Equipment',
         @v_EquipmentClassName)

      SET @v_RecordsAdded = @v_RecordsAdded + 1

-- Call the appropriate add property procedure based on the property's DataType   
      IF (@p_DataType = @c_DataTypeClass)
      BEGIN
         IF (@debug = 1) PRINT 'EXEC usp_EquipmentClassAddPropertyOfTypeClass ''' + @v_EquipmentClassName + ''',''' + 
	    	  	@v_EquipmentClassName + ''',''' + @p_PropertyName + ''''
         EXEC usp_EquipmentClassAddPropertyOfTypeClass 
              @v_EquipmentClassName,
              @v_EquipmentClassName,
              @p_PropertyName,
   	      @p_DataType,
	      @p_DefinedBy,
   	      @debug,
   	      @test,
	      @v_PropertiesAdded OUTPUT
      END
      ELSE
      BEGIN
         IF (@debug = 1) PRINT 'EXEC usp_EquipmentClassAddPropertyOfTypeScalar ''' + @v_EquipmentClassName + ''',''' + @p_PropertyName + ''''
         EXEC usp_EquipmentClassAddPropertyOfTypeScalar
              @v_EquipmentClassName,
              @p_PropertyName,
   			@p_Description,
   			@p_DataType,
              @p_UnitOfMeasure,
   			@p_Value,
			 0,		-- this is not a sub-property
   			@debug,
   			@test,
			@v_PropertiesAdded OUTPUT
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

      IF (@debug = 1) PRINT @v_ProcName + 'Trancount = ' + convert(varchar(5),@trancount)
      IF (@trancount = 0)
      BEGIN
         IF (@debug = 1) PRINT @v_ProcName + 'Committing ...'
         COMMIT
      END

      SET @v_RecordsAdded = @v_RecordsAdded + @v_PropertiesAdded
      SET @v_end_time = CURRENT_TIMESTAMP
	  SET @ReturnRecordsAdded = @v_RecordsAdded

-- done, print how many records were added by this routine
      PRINT @v_ProcName + 'Records Added: ' + CONVERT(VARCHAR(10),@v_RecordsAdded) + 
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