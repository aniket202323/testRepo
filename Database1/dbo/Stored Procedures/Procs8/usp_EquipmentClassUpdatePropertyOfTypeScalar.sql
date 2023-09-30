/* PROCEDURE: [usp_EquipmentClassUpdatePropertyOfTypeScalar] */

/* SYNOPSIS
 * This procedures is called by usp_EquipmentClassUpdateProperty to update a scalar (non-class property with DataType != 14) property.
 * The algorithm is as follows:
	- Update the Property_EquipmentClass table with the new property information
	- Update the Property_Equipment_EquipmentClass table to udpate the property for every instance that has that class
	- Find any properties that are defined by the parent class of this property.
	- For each, recursively update the changed sub-properties
 * END SYNOPSIS */

/* HISTORY
 * Created Nov. 27 by Ryan Berry
 * END HISTORY */

CREATE PROCEDURE [dbo].[usp_EquipmentClassUpdatePropertyOfTypeScalar]
@p_EquipmentClassName        NVARCHAR(200),
@p_PropertyName              NVARCHAR(200),
@p_UpdatedPropertyName       NVARCHAR(200),
@p_Description               NVARCHAR(255),    -- The property description
@p_DescriptionOverridden     BIT,			   -- Is the description overridden by this class
@p_DataType                  INT,              -- The property datatype
@p_UnitOfMeasure             NVARCHAR(255),    -- The property UnitOfMeasure
@p_UnitOfMeasureOverridden   BIT,			   -- Is the UoM overridden by this clas
@p_Value                     SQL_VARIANT,      -- The property default value
@p_ValueOverridden           BIT,				-- Is the value overridden by this class
@p_IsNested          BIT,				-- if 1, property is a nested property that is being updated as a result of a change to a different class
@debug			     BIT = 0,	 -- if 1, print debug statements
@test			     BIT = 0,    -- if 1, do not actually modify any records
@ReturnRecordsUpdated        INT OUTPUT	 -- return the number of records updated by this call
AS
   DECLARE @c_DataTypeClass  INT,
           @c_DataTypeGUID   INT,
   	   @i                INT,
		@iMax             INT,
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
	   @v_UpdatedSubPropName SYSNAME,
	   @trancount        INT,
	   @v_start_time     DATETIME,
	   @v_this_time      DATETIME,
	   @v_end_time       DATETIME,
	   @v_RecordsUpdated   INT,	
	   @v_SubPropertiesUpdated  INT,
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

	CREATE TABLE #tbl_EquipmentId (
   	   id            INT IDENTITY(1,1) not null)

   SET @v_start_time = CURRENT_TIMESTAMP
   SET @v_ProcName = 'L' + CONVERT(VARCHAR(2),@@NESTLEVEL) + ': usp_EquipmentClassUpdatePropertyOfTypeScalar: '
   SET @v_TrxName = 'EquipClassUpdatePropertyScalar'

   SET @v_RecordsUpdated       = 0
   SET @v_SubPropertiesUpdated = 0
   SET @ReturnRecordsUpdated = 0

   SET @c_GUIDEmpty = '00000000-0000-0000-0000-000000000000'

   PRINT ' '
   PRINT @v_ProcName + '  Start Time: ' + CONVERT(VARCHAR(23),@v_start_time)
   IF (@debug = 1) 
   BEGIN
      PRINT ' ' 
      PRINT @v_ProcName + 'Parameters: '
      PRINT @v_ProcName + '  p_PropertyName  = ' + @p_PropertyName
	  PRINT @v_ProcName + '  p_UpdatedPropertyName  = ' + @p_UpdatedPropertyName
      PRINT @v_ProcName + '  p_EquipClass    = ' + @p_EquipmentClassName
	  PRINT @v_ProcName + '  p_Description   = ' + @p_Description
	  PRINT @v_ProcName + '  p_DescriptionOverriden   = ' + CONVERT(VARCHAR(5),@p_DescriptionOverridden)
	  PRINT @v_ProcName + '  p_DataType = ' + CONVERT(VARCHAR(36),@p_DataType)
      PRINT @v_ProcName + '  p_UnitOfMeasure = ' + @p_UnitOfMeasure
      PRINT @v_ProcName + '  p_UnitOfMeasureOverridden = ' + CONVERT(VARCHAR(5),@p_UnitOfMeasureOverridden)
      PRINT @v_ProcName + '  p_Value         = ' + CONVERT(VARCHAR(255),@p_Value)
      PRINT @v_ProcName + '  p_ValueOverridden         = ' + CONVERT(VARCHAR(5),@p_ValueOverridden)
	  PRINT @v_ProcName + '  p_IsNested        = ' + CONVERT(VARCHAR(5), @p_IsNested)
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
       RAISERROR ('50100: Cannot use this proceure to update property %s as it is of type class.', 11, 1, @p_PropertyName)
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

-- Update record in Property_EquipmentClass
      IF (@debug = 1) PRINT @v_ProcName + 'UPDATE Property_EquipmentClass WHERE PropertyName = ' + @p_PropertyName + ' and EquipmentClassName = ' + @p_EquipmentClassName
      IF (@test = 0) 
	  BEGIN
	  
	  SET @v_this_time = CURRENT_TIMESTAMP
	  IF (@p_IsNested = 0) 		
		UPDATE dbo.Property_EquipmentClass SET
			PropertyName = @p_UpdatedPropertyName,
			Description = @p_Description,
			IsDescriptionOverridden = @p_DescriptionOverridden,
			DataType =  @p_DataType,
			UnitOfMeasure =  @p_UnitOfMeasure,
			IsUnitOfMeasureOverridden = @p_UnitOfMeasureOverridden,
			TimeStamp = @v_TimeStamp,
			Value = @v_Value,
			IsValueOverridden = @p_ValueOverridden,
			Version = Version + 1
		WHERE PropertyName = @p_PropertyName and EquipmentClassName = @p_EquipmentClassName

	ELSE 
		UPDATE dbo.Property_EquipmentClass SET
				PropertyName = @p_UpdatedPropertyName,
				Description = CASE WHEN ISNULL(IsDescriptionOverridden, 0) = 0 THEN @p_Description ELSE Description END,
				DataType =  @p_DataType,
				UnitOfMeasure =  CASE WHEN ISNULL(IsUnitOfMeasureOverridden, 0) = 0 THEN @p_UnitOfMeasure ELSE UnitOfMeasure END,
				TimeStamp = @v_TimeStamp,
				Value = CASE WHEN ISNULL(IsValueOverridden, 0) = 0 THEN @v_Value ELSE Value END,
				Version = Version + 1
		WHERE PropertyName = @p_PropertyName and EquipmentClassName = @p_EquipmentClassName
	  END

      SET @v_RecordsUpdated = @v_RecordsUpdated + 1
	  -- done, print how many records were updated by this step
      SET @v_end_time = CURRENT_TIMESTAMP
      PRINT @v_ProcName + 'Propery_EquipClass records modified: ' + CONVERT(VARCHAR(10),@@rowcount) + 
      	    		  	   ' in ' +  CONVERT(VARCHAR(10),DATEDIFF(ms,@v_this_time,@v_end_time)) + ' ms'

      IF (@debug = 1) PRINT @v_ProcName + 'UPDATE Property_Equipment_EquipmentClass WHERE Name = ' + @p_PropertyName + ' and EquipmentId IN (SELECT EquipmentId FROM [EquipmentClass_EquipmentObject] WHERE EquipmentClassName = ' + @p_EquipmentClassName
      SET @v_this_time = CURRENT_TIMESTAMP

		IF (@test = 0)
		BEGIN
   			UPDATE dbo.Property_Equipment_EquipmentClass SET 
				Name = @p_UpdatedPropertyName,
				Description = CASE WHEN IsDescriptionOverridden = 0 THEN ISNULL(@p_Description,'') ELSE Description END,
				UnitOfMeasure = CASE WHEN IsUnitOfMeasureOverridden = 0 THEN ISNULL(@p_UnitOfMeasure,'') ELSE UnitOfMeasure END,
				Value = CASE WHEN IsValueOverridden = 0 THEN @v_Value ELSE Value END,
				TimeStamp = @v_TimeStamp,
				Version = Version + 1
			WHERE Name = @p_PropertyName AND EquipmentId IN (SELECT EquipmentId FROM [EquipmentClass_EquipmentObject] WHERE EquipmentClassName = @p_EquipmentClassName)

			SET @v_SubPropertiesUpdated = @@rowcount
		END
		ELSE
        BEGIN
			SELECT @v_SubPropertiesUpdated = COUNT(*)
             FROM Property_Equipment_EquipmentClass
             WHERE Name = @p_PropertyName AND
				EquipmentId IN (SELECT EquipmentId FROM [EquipmentClass_EquipmentObject] WHERE EquipmentClassName = @p_EquipmentClassName)
        END

-- done, print how many records were updated by this step
      SET @v_end_time = CURRENT_TIMESTAMP
      PRINT @v_ProcName + 'Prop_Equip_EquipClass records modified: ' + CONVERT(VARCHAR(10),@v_SubPropertiesUpdated) + 
      	    		  	   ' in ' +  CONVERT(VARCHAR(10),DATEDIFF(ms,@v_this_time,@v_end_time)) + ' ms'

-- update running record count total
      SET @v_RecordsUpdated = @v_RecordsUpdated + @v_SubPropertiesUpdated

-- get the Id for the EquipmentClass of the property we are updating
      SELECT @v_ClassId = Id
        FROM dbo.EquipmentClass
		WHERE EquipmentClassName = @p_EquipmentClassName

      IF (@debug = 1) PRINT @v_ProcName + 'ClassId = ' + CONVERT(VARCHAR(36),@v_ClassId) + ' for EquipClassName ' + @p_EquipmentClassName

      --  Are there any other properties which have Class properties with the same class as our new property?
      INSERT INTO #tbl_StructTypeProp ([Name],DataType,TypeOwnerName) 
      SELECT Name,
			 DataType,
      	     TypeOwnerName
        FROM StructuredTypeProperty
       WHERE DefinedBy = @v_ClassId

      SELECT @iMax = @@rowcount, @i = 0

      IF (@debug = 1) 
         PRINT @v_ProcName + CONVERT(VARCHAR(3),@iMax) + 
	       		     ' StructuredTypeProperty records found WHERE DefinedBy = ' +  CONVERT(VARCHAR(36),@v_ClassId)

      -- For each Property found, do a recursive call to update subproperties of that class
      WHILE (@i < @iMax)
      BEGIN
         SELECT @i = @i + 1
         SELECT @v_PropertyName   = [Name],
                @v_DataType       = [DataType],
                @v_EquipClassName = [TypeOwnerName]
           FROM #tbl_StructTypeProp
          WHERE id = @i
         SET @v_SubPropName = @v_PropertyName + '.' +  @p_PropertyName 
		 SET @v_UpdatedSubPropName = @v_PropertyName + '.' + @p_UpdatedPropertyName

	 IF (@debug = 1)
	    PRINT @v_ProcName + 'EXEC usp_EquipmentClassUpdatePropertyOfTypeScalar ''' + @v_EquipClassName + ''',''' +  @v_SubPropName + ''''

	 EXEC usp_EquipmentClassUpdatePropertyOfTypeScalar 
	      @v_EquipClassName,
	      @v_SubPropName,
		  @v_UpdatedSubPropName,
	      @p_Description,
		  0,  -- description overridden, won't be updated for nested properties
	      @p_DataType,
	      @p_UnitOfMeasure,
		  0, -- UnitOfMeasure overridden, won't be updated for nested properties
	      @v_Value,
		  0, -- value overridden, won't be updated for nested properties
		  1, -- we are updated a nested property
	      @debug,
	      @test,
	      @v_SubPropertiesUpdated OUTPUT
         SET @v_RecordsUpdated =  @v_RecordsUpdated + @v_SubPropertiesUpdated
	 SET @v_SubPropertiesUpdated = 0
     END

-- set output variable
      SET @ReturnRecordsUpdated = @v_RecordsUpdated

      SET @v_end_time = CURRENT_TIMESTAMP

-- done, print how many records were updated by this routine
      PRINT @v_ProcName + 'Records Updated: ' + CONVERT(VARCHAR(10),@v_RecordsUpdated) + 
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