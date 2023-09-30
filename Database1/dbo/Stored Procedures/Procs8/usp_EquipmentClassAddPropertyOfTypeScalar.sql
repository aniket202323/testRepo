/* PROCEDURE: [usp_EquipmentClassAddPropertyOfTypeScalar] */

/* SYNOPSIS
 * This procedures is called by usp_EquipmentClassAddProperty to add a scalar (non-class property with DataType != 14) 
 * property to EquipmentClass.
 * This procedure does the following:
 * - Add record to Property_EquipmentClass table.
 * - For each record in EquipmentClass_EquipmentObject with the same EquipmentClassName value
 *      Add a record to Property_Equipqment_EquipmentClass table
 * - If there are other properties which have properties in the same class as the one we are adding
 *     Exec a recursive call to usp_EquipmentClassAddPropertyOfTypeScalar to add a compound sub-property name.
 * END SYNOPSIS */

/* NOTES
 * END NOTES */

/* HISTORY
 * BugFix_ May 29, 2013 by ll: explicit conversion of GUID in Property Value
 * BugFix_ May 03, 2013 by ll: fix length of transaction names
 * IncrDev May 01, 2013 by ll: replace table variables with temporary tables
 * IncrDev May 01, 2013 by ll: add timing and record count metrics
 * BugFix_ Apr 12, 2013 by ll: THROW is a SQLServer 2012 construct only, replaced with RAISERROR
 *                             specify column names on Property_Equipment_EquipmentClass INSERT
 * Created Mar 26, 2013 by ll:
 * END HISTORY */

CREATE PROCEDURE [dbo].[usp_EquipmentClassAddPropertyOfTypeScalar]
@p_EquipmentClassName        NVARCHAR(200),
@p_PropertyName              NVARCHAR(200),
@p_Description               NVARCHAR(255),
@p_DataType                  INT,
@p_UnitOfMeasure             NVARCHAR(255),
@p_Value                     SQL_VARIANT,
@p_IsSubProperty             BIT = 0,    -- if 1, then we are adding a sub-property 
@debug			     BIT = 0,	 -- if 1, print debug statements
@test			     BIT = 0,    -- if 1, do not actually add any records
@ReturnRecordsAdded          INT OUTPUT	 -- return the number of records added by this call
AS
   DECLARE @c_DataTypeClass  INT,
           @c_DataTypeGUID   INT,
   	   @i                INT,
   	   @j                INT,
    	   @iMax             INT,
    	   @iMaxEquip        INT,
	   @v_DataType       INT,
	   @v_Value          SQL_VARIANT,
	   @v_TimeStamp      DATETIME,
	   @v_ClassId        UNIQUEIDENTIFIER,
	   @v_EquipmentId    UNIQUEIDENTIFIER,
	   @v_EquipClassName SYSNAME,
	   @v_ProcName       VARCHAR(100),
	   @V_TrxName        VARCHAR(32),
	   @v_PropertyName   SYSNAME,
  	   @v_SubPropName    SYSNAME,
	   @v_Overridden     BIT,
	   @trancount        INT,
	   @v_start_time     DATETIME,
	   @v_this_time      DATETIME,
	   @v_end_time       DATETIME,
	   @v_RecordsAdded   INT,	
	   @v_SubPropertiesAdded  INT,
	   @c_GUIDEmpty      UNIQUEIDENTIFIER

-- table variable to hold the list of Name, TypeOwnerName values from StructuredTypeProperty
   CREATE TABLE #tbl_StructTypeProp (
   	   id            INT IDENTITY(1,1) not null,
	   Name          SYSNAME,
	   DataType      INT,
	   TypeOwnerName SYSNAME)

-- table variable to hold records for Property_Equipment_EquipmentClass

   CREATE TABLE #tbl_Prop_Equip_EquipClass (
   	   Name                                      NVARCHAR(255) NOT NULL,
	   Class                                     NVARCHAR(255),
	   Constant                                  BIT,
	   Id                                        NVARCHAR(255),
	   IsTemplate                                BIT,
	   Description                               NVARCHAR(255),
	   UnitOfMeasure                             NVARCHAR(255),
	   IsUnitOfMeasureOverridden                 BIT,
	   IsDescriptionOverridden                   BIT,
	   IsValueOverridden                         BIT,
	   TimeStamp                                 DATETIME,
	   Value                                     SQL_VARIANT,
	   Version                                   BIGINT,
	   EquipmentId                               UNIQUEIDENTIFIER NOT NULL,
	   ItemId                                    UNIQUEIDENTIFIER)

   SET @v_start_time = CURRENT_TIMESTAMP
   SET @v_ProcName = 'L' + CONVERT(VARCHAR(2),@@NESTLEVEL) + ': usp_EquipmentClassAddPropertyOfTypeScalar: '
   SET @v_TrxName = 'EquipClassAddPropertyScalar'

   SET @v_RecordsAdded       = 0
   SET @v_SubPropertiesAdded = 0
   SET @ReturnRecordsAdded   = 0

   SET @c_GUIDEmpty = '00000000-0000-0000-0000-000000000000'

   PRINT ' '
   PRINT @v_ProcName + '  Start Time: ' + CONVERT(VARCHAR(23),@v_start_time)
   IF (@debug = 1) 
   BEGIN
      PRINT ' ' 
      PRINT @v_ProcName + 'Parameters: '
      PRINT @v_ProcName + '  p_PropertyName  = ' + @p_PropertyName
      PRINT @v_ProcName + '  p_EquipClass    = ' + @p_EquipmentClassName
      PRINT @v_ProcName + '  p_Description   = ' + @p_Description
      PRINT @v_ProcName + '  p_UnitOfMeasure = ' + @p_UnitOfMeasure
      PRINT @v_ProcName + '  p_Value         = ' + CONVERT(VARCHAR(255),@p_Value)
      PRINT @v_ProcName + '  p_IsSubProperty = ' + CONVERT(VARCHAR(1),@p_IsSubProperty)
      PRINT @v_ProcName + 'End Parameters'
      PRINT ' ' 
   END

-- The Class DataType indicator value is 14, GUID is 6 
/* DEVELOPER_ATTENTION: These are dependant on the value of the DataTypes in the C# method. */
/* DOC: The datatype is from the SupportedTypes Array in the
 *      Proficy.Platform.Core.ProficySystem.Types.SystemDataTypes class.
 *      The SystemDataTypes.GetDataTypeId(newProperty.DataType)
 *      returns an integer value used as the dataType parameter which is used
 *      in these stored procedures.
 */
   SET @c_DataTypeClass = 14
   SET @c_DataTypeGUID  = 6

-- sanity check, this shouldn't happen
   IF (@p_DataType = @c_DataTypeClass)
   BEGIN
/* DEVELOPER_ATTENTION: 
   Severity = 11, State = 1 not sure if these are correct
   See http://msdn.microsoft.com/en-us/library/ms178592.aspx for explanation of these
 */
       RAISERROR ('50100: Use procedure usp_EquipmentClassAddPropertyOfTypeClass to add Property "%s".', 11, 1, @p_PropertyName)
       RETURN
   END

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
	 SAVE TRANSACTION @v_TRxName
      END

/* DOC: When adding a sub-property (a property from another Class property) the Overridden values must be NULL,
        Otherwise, the are defaulted to 1 */
   IF (@p_IsSubProperty = 0)
      SET @v_Overridden = 1
   ELSE
      SET @v_Overridden = NULL

/* DOC: Need to explicitly convert a GUID value so it can be retreived as a GUID on the way back out */
   IF (@p_DataType = @c_DataTypeGUID)
    BEGIN
-- If the Value is an empty GUID, just do a straight conversion of @c_GUIDEmpty to sql_variant 
      IF (CONVERT(VARCHAR(36),@p_Value) = CONVERT(VARCHAR(36),@c_GUIDEmpty))
         SET @v_Value = CONVERT(SQL_VARIANT,@c_GUIDEmpty)
      ELSE
-- Otherwise, convert the sql_variant Value to GUID datatype, and then back to sql_variant
         SET @v_Value = CONVERT(SQL_VARIANT,CONVERT(UNIQUEIDENTIFIER,@p_Value))
    END
   ELSE
      SET @v_Value = @p_Value

-- Insert record into Property_EquipmentClass
      IF (@debug = 1) 
         PRINT @v_ProcName + 'INSERT INTO Property_EquipmentClass (' + @p_PropertyName + ',' + @p_EquipmentClassName + ')'
      IF (@test = 0)
      INSERT INTO dbo.Property_EquipmentClass (
         PropertyName,
         Description,
         DataType,
         UnitOfMeasure,
         Constant,
         IsValueOverridden,
         IsDescriptionOverridden,
         IsUnitOfMeasureOverridden,
         [TimeStamp],
         [Value],
         Version,
         EquipmentClassName,
         ItemId)
      VALUES (
         @p_PropertyName,
         @p_Description,  
         @p_DataType,
         @p_UnitOfMeasure, 
	 0,	                      -- Constant
	 @v_Overridden,@v_Overridden,@v_Overridden,  -- [IsValue|IsDescription|IsUnitOfMeasure]Overridden
         @v_TimeStamp,
         @v_Value,
         1,			-- always 1 when creating new property record
         @p_EquipmentClassName,
         NULL)
      SET @v_RecordsAdded = @v_RecordsAdded + 1

      IF (@debug = 1) 
         PRINT @v_ProcName + 'INSERT INTO Property_Equipment_EquipmentClass (' + @p_PropertyName + ',' + @p_EquipmentClassName + ')'
      SET @v_this_time = CURRENT_TIMESTAMP
--      IF (@test = 0)
      IF (0 = 0)
       BEGIN
--          INSERT INTO Property_Equipment_EquipmentClass (
           INSERT INTO #tbl_Prop_Equip_EquipClass (
            Name,
            Class,
            Constant,
            Id,
            IsTemplate,
            Description,
            UnitOfMeasure,
            IsUnitOfMeasureOverridden,
            IsDescriptionOverridden,
            IsValueOverridden,
            TimeStamp,
            Value,
            Version,
            EquipmentId,
            ItemId)
	  SELECT
            @p_PropertyName,
   	    @p_EquipmentClassName,
   	    0,			-- Constant always 0 for new Property
   	    NEWID(),		-- generate a GUID for this record
   	    NULL,		-- IsTemplate always NULL for new property
   	    @p_Description,   
	    @p_UnitOfMeasure, 
   	    0,			-- IsUnitOfMeasureOverridden, always false for this table
   	    0,			-- IsDescriptionOverridden, always false
   	    0,			-- IsValueOverrriden always false
   	    @v_TimeStamp,
	    @v_Value,
   	    1,			-- default Version to 1 for newly inserted records
   	    EquipmentId,
   	    NULL
           FROM [EquipmentClass_EquipmentObject]
          WHERE EquipmentClassName = @p_EquipmentClassName
	  SET @v_SubPropertiesAdded = @@rowcount
        END
      ELSE
        BEGIN
	    SELECT @v_SubPropertiesAdded = COUNT(*)
              FROM [EquipmentClass_EquipmentObject]
             WHERE EquipmentClassName = @p_EquipmentClassName
        END

-- done, print how many records were added by this step
      SET @v_end_time = CURRENT_TIMESTAMP
      PRINT @v_ProcName + 'Prop_Equip_EquipClass records added: ' + CONVERT(VARCHAR(10),@v_SubPropertiesAdded) + 
      	    		  	   ' in ' +  CONVERT(VARCHAR(10),DATEDIFF(ms,@v_this_time,@v_end_time)) + ' ms'
-- update running record count total
      SET @v_RecordsAdded = @v_RecordsAdded + @v_SubPropertiesAdded

      -- get the Id for the EquipmentClass of the property we are adding
      SELECT @v_ClassId = Id
        FROM dbo.EquipmentClass
       WHERE EquipmentClassName = @p_EquipmentClassName

      IF (@debug = 1) 
         PRINT @v_ProcName + 'ClassId = ' + CONVERT(VARCHAR(36),@v_ClassId) + ' for EquipClassName ' + @p_EquipmentClassName

      --  Are there any other properties which have Class properties with the same class as our new property?
      INSERT INTO #tbl_StructTypeProp ([Name],DataType,TypeOwnerName) 
      SELECT Name,
	     DataType,
      	     TypeOwnerName
        FROM dbo.StructuredTypeProperty
       WHERE DefinedBy = @v_ClassId
      SELECT @iMax = @@rowcount, @i = 0

      IF (@debug = 1) 
         PRINT @v_ProcName + CONVERT(VARCHAR(3),@iMax) + 
	       		     ' StructuredTypeProperty records found WHERE DefinedBy = ' +  CONVERT(VARCHAR(36),@v_ClassId)

      -- For each Property found, do a recursive call to add our new Property as subproperty of that class
      WHILE (@i < @iMax)
      BEGIN
         SELECT @i = @i + 1
         SELECT @v_PropertyName   = [Name],
                @v_DataType       = [DataType],
                @v_EquipClassName = [TypeOwnerName]
           FROM #tbl_StructTypeProp
          WHERE id = @i
         SET @v_SubPropName = @v_PropertyName + '.' +  @p_PropertyName 

	 IF (@debug = 1)
	    PRINT @v_ProcName + 'EXEC usp_EquipmentClassAddPropertyOfTypeScalar ''' + @v_EquipClassName + ''',''' +  @v_SubPropName + ''''

	 EXEC usp_EquipmentClassAddPropertyOfTypeScalar 
	      @v_EquipClassName,
	      @v_SubPropName,
	      @p_Description,
	      @p_DataType,
	      @p_UnitOfMeasure,
	      @v_Value,
	      1, -- subProperty
	      @debug,
	      @test,
	      @v_SubPropertiesAdded OUTPUT
         SET @v_RecordsAdded =  @v_RecordsAdded + @v_SubPropertiesAdded
	 SET @v_SubPropertiesAdded = 0
      END

-- Insert all of the records we've collected
      IF (@test = 0)
      BEGIN
          INSERT INTO dbo.Property_Equipment_EquipmentClass (
              Name,
              Class,
              Constant,
              Id,
              IsTemplate,
              Description,
              UnitOfMeasure,
              IsUnitOfMeasureOverridden,
              IsDescriptionOverridden,
              IsValueOverridden,
              TimeStamp,
              Value,
              Version,
              EquipmentId,
              ItemId)
          SELECT
              Name,
              Class,
              Constant,
              Id,
              IsTemplate,
              Description,
              UnitOfMeasure,
              ISNULL(IsUnitOfMeasureOverridden,0),
              ISNULL(IsDescriptionOverridden,0),
              ISNULL(IsValueOverridden,0),
              TimeStamp,
              Value,
              Version,
              EquipmentId,
              ItemId
            FROM #tbl_Prop_Equip_EquipClass
          SET @v_SubPropertiesAdded = @@rowcount
        END
      ELSE
         SELECT @v_SubPropertiesAdded = COUNT(*)
           FROM #tbl_Prop_Equip_EquipClass

      IF (@debug = 1) PRINT @v_ProcName + 'Trancount = ' + convert(varchar(5),@trancount)
      IF (@trancount = 0)
      BEGIN
-- Commit  
        PRINT @v_ProcName + 'SubProperties added from #tbl: ' + CONVERT(VARCHAR(10),@v_SubPropertiesAdded)
        IF (@debug = 1) PRINT @v_ProcName + 'Committing ...'
        COMMIT
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