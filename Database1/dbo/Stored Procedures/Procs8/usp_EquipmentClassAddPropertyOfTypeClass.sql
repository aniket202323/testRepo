/* PROCEDURE: [usp_EquipmentClassAddPropertyOfTypeClass] */

/* SYNOPSIS
 * This procedure is called by usp_EquipmentClassAddProperty to add an EquipmentClassProperty 
 * which is itself of type Class. (DataType = 14)
 * END SYNOPSIS */

 /* NOTES
 * Algorithm:
 * For each <PropertyName> in <ClassName> which is itself a Class (DataType = 14)
 * The parameter p_ClassId contains the value of the EquipmentClass.Id for p_EquipmentClassName
 *         ie: WHERE StructuredTypeProperty.Name               = <PropertyName> 
 *               AND StructuredTypeProperty.TypeOwnerName      = <ClassName> 
 *               AND StructuredTypeProperty.TypeOwnerNamespace = N'Equipment'
 *    - Query EquipmentClass by Id and fetch the EquipmentClassName. This is <ClassName>.
 *        ie: WHERE EquipmentClass.Id.<DefinedBy>
 *      Query the Property_EquipmentClass table to get the list of Properties for <ClassName>
 *        ie: WHERE Property_EquipmentClass.EquipmentClassName = <ClassName>
 *      For each <PropertyName>
 *            Call usp_EquipmentClassAddPropertyOfTypeScalar to add the subproperty to the class.
 * END NOTES */

/* HISTORY
 * Dec 02, 2012 by R Berry : simplify algorithm to add child properties (simply copy from Property_EquipmentClass table rather than rescursively add)
 * BugFix_ May 03, 2013 by ll: fix length of transaction names
 * IncrDev May 01, 2013 by ll: replace table variables with temporary tables
 * IncrDev May 01, 2013 by ll: add timing and record count metrics
 * BugFix_ Apr 12, 2013 by ll: THROW is a SQLServer 2012 construct only, replaced with RAISERROR
 * Created Mar 27, 2013 by ll:
 * END HISTORY */

CREATE PROCEDURE [dbo].[usp_EquipmentClassAddPropertyOfTypeClass]
@p_ParentEquipmentClassName NVARCHAR(200),    -- top-level EquipmentClassName to which we are adding the new property
@p_EquipmentClassName       NVARCHAR(200),    -- EquipmentClassName to which we are adding the sub-property (in case of recursive call)
@p_PropertyName             NVARCHAR(200),    -- PropertyName of the new property we are trying to add 
@p_DataType                 INT,              -- Should be 14 to indicate that the property is a Class property
@p_ClassId                  UNIQUEIDENTIFIER, -- This is the EquipmentClass.Id of the new Property's class
@debug                      BIT = 0,	      -- if 1, print debug statements
@test			    BIT = 0, 	      -- if 1, do not actually add any records
@ReturnRecordsAdded         INT OUTPUT        -- return the number of records added by this call
AS
   DECLARE @c_DataTypeClass  INT,
   	   @i                INT,
           @iMax             INT,
	   @v_DataType       INT,
	   @v_ClassId        UNIQUEIDENTIFIER,
	   @v_EquipClassName NVARCHAR(200),
	   @v_ProcName       VARCHAR(100),
	   @v_TrxName        VARCHAR(32),
	   @v_PropName       NVARCHAR(200),
  	   @v_SubPropName    NVARCHAR(200),
	   @v_PropDesc       NVARCHAR(255),
	   @v_UofMeasure     NVARCHAR(255),
	   @v_Value          SQL_VARIANT,
	   @trancount        INT,
	   @v_start_time     DATETIME,
	   @v_end_time       DATETIME,
	   @v_RecordsAdded   INT,
	   @v_SubPropertiesAdded   INT

-- temporary table to hold the list of EquipmentId values from StructuredTypeProperty
   CREATE TABLE #tbl_StructTypePropClass  (
   	   id          INT IDENTITY(1,1) not null,
	   Name        NVARCHAR(200),
	   DefinedBy   UNIQUEIDENTIFIER,
	   DataType    INT)

	   -- temporary table to hold the child properties
   CREATE TABLE #tbl_ClassProperties  (
   	   id          INT IDENTITY(1,1) not null,
	   Name        NVARCHAR(200),
	   Description NVARCHAR(200),
	   DataType    INT,
	   UnitOfMeasure NVARCHAR(255),
	   Value SQL_VARIANT,

	   )

   SET @v_start_time = CURRENT_TIMESTAMP
   SET @v_ProcName = 'L' + CONVERT(VARCHAR(2),@@NESTLEVEL) + ': usp_EquipmentClassAddPropertyOfTypeClass: '
   SET @v_TrxName = 'EquipClassAddPropClass'

   SET @v_RecordsAdded       = 0
   SET @v_SubPropertiesAdded = 0
   SET @ReturnRecordsAdded   = 0

   PRINT ' '
   PRINT @v_ProcName + '  Start Time: ' + CONVERT(VARCHAR(23),@v_start_time)
   IF (@debug = 1) 
   BEGIN
      PRINT ' '
      PRINT @v_ProcName + 'Parameters: '
      PRINT @v_ProcName + '  p_ParentEquipClass = ' + @p_ParentEquipmentClassName
      PRINT @v_ProcName + '  p_EquipClass       = ' + @p_EquipmentClassName
      PRINT @v_ProcName + '  p_PropertyName     = ' + @p_PropertyName
      PRINT @v_ProcName + '  p_EquipClassId     = ' + CONVERT(VARCHAR(36),@p_ClassId)
      PRINT @v_ProcName + 'End Parameters'
      PRINT ' '
   END

-- The Class DataType indicator value is 14 
/* DEVELOPER_ATTENTION: These are dependant on the value of the DataTypes in the C# method. */
/* DOC: The datatype is from the SupportedTypes Array in the
 *      Proficy.Platform.Core.ProficySystem.Types.SystemDataTypes class.
 *      The SystemDataTypes.GetDataTypeId(newProperty.DataType)
 *      returns an integer value used as the dataType parameter which is used
 *      in these stored procedures.
 */
   SET @c_DataTypeClass = 14

-- sanity check (this shouldn't happen)
   IF (@p_DataType != @c_DataTypeClass)
   BEGIN
/* DEVELOPER_ATTENTION: 
   Severity = 11, State = 1 not sure if these are correct
   See http://msdn.microsoft.com/en-us/library/ms178592.aspx for explanation of these
 */
       RAISERROR ('50100: Use procedure usp_EquipmentClassAddPropertyOfTypeScalar to add Property "%s".', 11, 1, @p_PropertyName)
       RETURN
   END

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
	 SAVE TRANSACTION @v_TrxName
      END

      -- Fetch the EquipmentClassName for the @p_ClassId parameter from the EquipmentClass table 
      SELECT @v_EquipClassName = [EquipmentClassName]
        FROM dbo.EquipmentClass
       WHERE EquipmentClass.Id = @p_ClassId
       IF (@debug = 1) PRINT @v_ProcName + 'v_EquipClassName = ' + @v_EquipClassName

	INSERT INTO #tbl_ClassProperties (Name, Description, DataType, UnitOfMeasure, Value)
	    SELECT PropertyName, Description, DataType, UnitOfMeasure, Value
         FROM dbo.Property_EquipmentClass
         WHERE EquipmentClassName = @v_EquipClassName


	SELECT @iMax = @@rowcount, @i = 0
	WHILE (@i < @iMax)
	BEGIN
		SELECT @i = @i + 1
		SELECT @v_SubPropName = @p_PropertyName + '.' + Name, 
				@v_PropDesc = Description,
   	        @v_DataType = [DataType],
			@v_UofMeasure = UnitOfMeasure,
			@v_Value = Value
           FROM #tbl_ClassProperties
          WHERE id = @i

		IF (@debug = 1) PRINT @v_ProcName + 'EXEC usp_EquipmentClassAddPropertyOfTypeScalar ''' +  @p_ParentEquipmentClassName + ''',''' +  @v_SubPropName + ''''
		EXEC usp_EquipmentClassAddPropertyOfTypeScalar
		    @p_ParentEquipmentClassName,
	    	    @v_SubPropName,
	    	    @v_PropDesc,	-- Description
		    @v_DataType,
		    @v_UOfMeasure,      -- UnitofMeasure
		    @v_Value,		-- Value
		    1,			-- note that we are adding a sub-property
		    @debug,@test,
		    @v_SubPropertiesAdded OUTPUT

		SET @v_RecordsAdded       = @v_RecordsAdded + @v_SubPropertiesAdded
		SET @v_SubPropertiesAdded = 0

	 END

-- set output variable
      SET @ReturnRecordsAdded = @v_RecordsAdded

      SET @v_end_time = CURRENT_TIMESTAMP

-- done, print how many records were added by this routine
      PRINT @v_ProcName + 'Records Added: ' + CONVERT(VARCHAR(10),@v_RecordsAdded) + 
      	    		  	   ' in ' +  CONVERT(VARCHAR(10),DATEDIFF(ms,@v_start_time,@v_end_time)) + ' ms'
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