/* PROCEDURE: [usp_EquipmentClassRenamePropertyOfTypeClass] */

/* SYNOPSIS
 * This procedures is called by usp_EquipmentClassUpdateProperty to rename a class property (DataType == 14) .
 * The algorithm is as follows:
	- Update all the subproperty names in the Property_EquipmentClass table with the new parent property prefix
	- Update the Property_Equipment_EquipmentClass table with the new prefix for every instance that has that class
	- Find any properties that are defined by the parent class of this property.
	- For each, recursively perform the rename
 * END SYNOPSIS */

/* HISTORY
 * Created Nov. 27 by Ryan Berry
 * END HISTORY */

CREATE PROCEDURE [dbo].[usp_EquipmentClassRenamePropertyOfTypeClass]
@p_EquipmentClassName       NVARCHAR(200),    -- EquipmentClassName for which we are renaming the property
@p_ClassId        UNIQUEIDENTIFIER,			  -- GUID of the EquipmentClass for which we are renaming the property
@p_PropertyName             NVARCHAR(200),    -- Old property name
@p_UpdatedPropertyName     NVARCHAR(200),    --  New property name
@debug                      BIT = 0,	      -- if 1, print debug statements
@ReturnRecordsUpdated        INT OUTPUT	 -- return the number of records added by this call

AS
   DECLARE @c_DataTypeClass  INT,
   	   @i                INT,
       @iMax             INT,
	   @v_DataType       INT,
	   @v_ClassId        UNIQUEIDENTIFIER,
	   @v_EquipClassName NVARCHAR(200),
	   @v_ProcName       VARCHAR(100),
	   @v_TrxName        VARCHAR(32),
	   @trancount        INT,
	   @v_start_time     DATETIME,
	   @v_end_time       DATETIME,
	   @v_RecordsModified   INT,
	   @v_ParentRecordsModified   INT

-- temporary table to hold the list of EquipmentId values from StructuredTypeProperty
   CREATE TABLE #tbl_StructTypePropClass  (
   	   id          INT IDENTITY(1,1) not null,
	   Name        NVARCHAR(200),
	   ClassName   NVARCHAR(200))

   SET @v_start_time = CURRENT_TIMESTAMP
   SET @v_ProcName = 'L' + CONVERT(VARCHAR(2),@@NESTLEVEL) + ': usp_EquipmentClassRenamePropertyOfTypeClass: '
   SET @v_TrxName = 'EquipClassRenamePropClass'

   SET @v_RecordsModified       = 0
   SET @v_ParentRecordsModified = 0

   PRINT ' '
   PRINT @v_ProcName + '  Start Time: ' + CONVERT(VARCHAR(23),@v_start_time)
   IF (@debug = 1) 
   BEGIN
      PRINT ' '
      PRINT @v_ProcName + 'Parameters: '
      PRINT @v_ProcName + '  p_EquipClass       = ' + @p_EquipmentClassName
      PRINT @v_ProcName + '  p_PropertyName     = ' + @p_PropertyName
	  PRINT @v_ProcName + '  p_UpdatedPropertyName = ' + @p_UpdatedPropertyName
      PRINT @v_ProcName + 'End Parameters'
      PRINT ' '
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


		-- Update property prefix in the Property_EquipmentClass table. (e.g. Old.Property -> New.Property)
		IF (@debug = 1) PRINT 'UPDATE Property_EquipmentClass WHERE EquipmentClassName = ' + @p_EquipmentClassName + ' and PropertyName like ' +  @p_PropertyName + '.%'
		UPDATE [Property_EquipmentClass] 
		SET PropertyName = @p_UpdatedPropertyName + SUBSTRING(PropertyName, LEN(@p_PropertyName) + 1, LEN(PropertyName)) -- New prefix plus the non-prefix part of the name
		WHERE EquipmentClassName = @p_EquipmentClassName and PropertyName like @p_PropertyName + '.%'

		SET @v_RecordsModified = @v_RecordsModified + @@rowcount

		-- Update property prefix in the Property_Equipment_EquipmentClass table. (e.g. Old.Property -> New.Property)
		IF (@debug = 1) PRINT 'UPDATE Property_Equipment_EquipmentClass WHERE Class = ' + @p_EquipmentClassName + ' and Name like ' +  @p_PropertyName + '.%'
		UPDATE [Property_Equipment_EquipmentClass] 
		SET Name = @p_UpdatedPropertyName + SUBSTRING(Name, LEN(@p_PropertyName) + 1, LEN(Name)) -- New prefix plus the non-prefix part of the name
		WHERE Class = @p_EquipmentClassName and Name like @p_PropertyName + '.%'

		SET @v_RecordsModified = @v_RecordsModified + @@rowcount

	  -- Find any properties on other classes that are defined by the class we just updated
	    INSERT INTO #tbl_StructTypePropClass (Name,ClassName)
			SELECT Name, TypeOwnerName
			FROM StructuredTypeProperty
			WHERE DefinedBy      = @p_ClassId AND TypeOwnerNamespace = N'Equipment'

	 -- For each "implementing" property, perform a rename of all its subproperties	
		SELECT @iMax = @@rowcount, @i = 0
		IF (@debug = 1) PRINT 'Renaming subproperties for ' + CONVERT(NVARCHAR,@iMax) + ' properties that are defined by class  ' + @p_EquipmentClassName
		WHILE (@i < @iMax)
		BEGIN
			DECLARE @v_ImplementingPropertyName nvarchar(200)
			DECLARE @v_ContainingClassName nvarchar(200)
			DECLARE @v_ContainingClassId uniqueidentifier
			DECLARE @v_OldSubpropertyName nvarchar(400)
			DECLARE @v_NewSubpropertyName nvarchar(400)

			SELECT @i = @i + 1
			SELECT @v_ImplementingPropertyName = [Name]
				FROM #tbl_StructTypePropClass
				WHERE id = @i
			SELECT @v_ContainingClassName = [ClassName]
				FROM #tbl_StructTypePropClass
				WHERE id = @i
			SELECT	@v_ContainingClassId = [Id] 
				FROM [EquipmentClass]
				WHERE [EquipmentClassName] = @v_ContainingClassName

			SET @v_OldSubpropertyName = @v_ImplementingPropertyName + '.' + @p_PropertyName
			SET @v_NewSubpropertyName = @v_ImplementingPropertyName + '.' + @p_UpdatedPropertyName

		 -- Recursively perform the rename
			EXEC usp_EquipmentClassRenamePropertyOfTypeClass 
				@v_ContainingClassName,
				@v_ContainingClassId,
				@v_OldSubpropertyName,
				@v_NewSubpropertyName,
				@debug,
				@v_ParentRecordsModified OUTPUT

			SET @v_RecordsModified = @v_RecordsModified + @v_ParentRecordsModified
		END

      SET @v_end_time = CURRENT_TIMESTAMP
	  SET @ReturnRecordsUpdated = @v_RecordsModified

---- done, print how many records were modified by this routine
      PRINT @v_ProcName + 'Records Modified: ' + CONVERT(VARCHAR(10),@v_RecordsModified) + 
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