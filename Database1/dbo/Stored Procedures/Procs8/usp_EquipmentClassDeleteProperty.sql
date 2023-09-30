
/* PROCEDURE: [usp_EquipmentClassDeleteProperty] */

/* SYNOPSIS
 * Delete a property from EquipmentClass.
 * The algorithm is as follows:
 * - Deletes All references to the Property on any Equipment that has EquipmentClass associated
 * - Checks for all Ancestor-Classes or Equipments using this Class
 * - 	ON each Equipment: Deletes all properties inside any local property that is made of the class or ancestor-class type
 * - 		Update EquipmentClass record for Equipment to bump the version
 * - 	ON Ancestor-Classes: Deletes the property from the ancestor-class (Recursive Call to this SP)	
 * - Deletes the property from original EquipmentClass.
 * - Updates EquipmentClass record to bump the version
 * - Deletes property-class association on StructuredTypeProperty 
 * END SYNOPSIS */

/* NOTES
 * END NOTES */

/* HISTORY
 * IncrDev Mar 19, 2014 by RG: Replaced usage of IsGuid SP with a single select statement to check for correct GUID format.
 * Created Mar 14, 2014 by Raul Guia:
 * END HISTORY */
 

create Procedure[dbo].[usp_EquipmentClassDeleteProperty]
	@p_EquipmentClassId          UNIQUEIDENTIFIER, -- GUID of the EquipmentCLass
	@p_PropertyName              NVARCHAR(200),    -- The property name
	@debug                       BIT = 0,          -- if 1, print debug statements
	@test                        BIT = 0           -- if 1, do not actually delete any records
as

-----------------------------
-- Local Variables Definition
--
declare
	@v_EquipmentClassName NVARCHAR(200),
	@v_PropNameRoot		  VARCHAR(100),
	
	@v_PropName			  NVARCHAR(200),
	@V_TypeOwnerName	  NVARCHAR(200),
	@v_IsGuidOut		  INT,

	@v_LocalClassId		  UNIQUEIDENTIFIER,
	@v_LocalPropName	  VARCHAR(100),

	@v_ProcName			  VARCHAR(100),
	@v_TrxName			  VARCHAR(32),
	@trancount			  INT,
	
    @iMax				  INT,
   	@i					  INT,
	
	@v_PropertyName		  SYSNAME,
    @v_EquipClassName	  SYSNAME,
    @v_DataType			  INT,
	
    @v_RowCount			  INT,
	@v_TimeStamp		  DATETIME
    

-- table variable to hold the list of Name, TypeOwnerName values from StructuredTypeProperty
create table #tbl_StructTypeProp (
   	   id            INT IDENTITY(1,1) not null,
	   Name          SYSNAME,
	   DataType      INT,
	   TypeOwnerName SYSNAME)

SET @v_ProcName =  'L' + CONVERT(VARCHAR(2),@@NESTLEVEL) + ': usp_EquipmentClassDeleteProperty: '
IF (@debug = 1)
BEGIN
  PRINT ' '
  PRINT @v_ProcName + 'Parameters:'
  PRINT @v_ProcName + '  Nested level     = ' + CONVERT(VARCHAR(5),@@NESTLEVEL)
  PRINT @v_ProcName + '  EquipmentClassId = ' + CONVERT(VARCHAR(36),@p_EquipmentClassId)
  PRINT @v_ProcName + '  PropertyName     = ' + @p_PropertyName
  PRINT @v_ProcName + 'End Parameters'
  PRINT ' ' 
END

-- initialize the timestamp
SET @v_TimeStamp = (SELECT CURRENT_TIMESTAMP)


SET NOCOUNT ON
SET @trancount = @@trancount

BEGIN try
	IF @trancount = 0
	BEGIN
		print 'begin transaction...'
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		print 'save transaction... ' +  @v_ProcName
		SAVE TRANSACTION @v_ProcName
	END

	-----------------------------
	-- Get the EquipmentClassName
	--
	set @v_EquipmentClassName = (SELECT EquipmentClassName
								   FROM EquipmentClass
				 				  WHERE Id = @p_EquipmentClassId)

	-------------------------------------------------
	-- Verify that we have a valid EquipmentClassName 
	--
	if (@v_EquipmentClassName IS NULL)
	begin
		raiserror('50101: Equipment Class not found.', 11, 1)
		return
	end
	
	-------------------------------------------
	-- DELETE All references to Property on any 
	-- Equipment that has Compromised Class associated
	--
	if (@debug = 1)
		print  'delete from  '
		print  '	 Property_Equipment_EquipmentClass '
		print  'where ' 
		print  '	 Class = ''' + @v_EquipmentClassName + '''' 
		print  'and  Name like ''' + @p_PropertyName + '%'''
		print  ''

	if (Not @test = 1)
		delete from 
			Property_Equipment_EquipmentClass 
		where
			Class = @v_EquipmentClassName 
		and Name like @p_PropertyName + '%'
	else
		select * from
			Property_Equipment_EquipmentClass 
		where
			Class = @v_EquipmentClassName 
		and Name like @p_PropertyName + '%'
		
	------------------------------------------------------------------
	-- LOOP: Check all Ancestor-Classes or Equipments using this Class
	--
    insert into #tbl_StructTypeProp ([Name],DataType,TypeOwnerName) 
	select Name,
		   DataType,
      	   TypeOwnerName
	from 
		StructuredTypeProperty 
	where 
		DefinedBy = @p_EquipmentClassId	
		
    select @iMax = @@rowcount, @i = 0
    
    while (@i < @iMax)
    begin
		select @i = @i + 1
		select @v_PropNameRoot   = [Name],
				@v_DataType      = [DataType],
				@v_TypeOwnerName = [TypeOwnerName]
		from #tbl_StructTypeProp
		where id = @i
          
		---------------------------------------------------------------------------------
		-- Chceck if @V_TypeOwnerName is a guid (Which indicates that it is an equipment id)
		-- or not (which indicates that it is a Class Name)
        set @v_IsGuidOut = (SELECT 1 WHERE @V_TypeOwnerName LIKE REPLACE('00000000-0000-0000-0000-000000000000', '0', '[0-9a-fA-F]'))
  
		if(@v_IsGuidOut = 1)
			begin
				----------------------------------------------------------------------------------------------------------------
				-- DELETE All the property inside any local property on equipment that is 
				-- made of the class or ancestor-class type  from Property_Equipment_EquipmentClass and Property_EquipmentClass 
				--
				if (@debug = 1)
					print 'delete from '
					print '    Property_Equipment_EquipmentClass '
					print 'where '
					print '    EquipmentId = ''' + @v_TypeOwnerName + ''''
					print 'and Name like ''' + @v_PropNameRoot + '.' + @p_PropertyName + '%'''			
					print ''
					
				if (Not @test = 1)		
					delete from  
						Property_Equipment_EquipmentClass 
					where 
						EquipmentId = @v_TypeOwnerName 
					and Name like @v_PropNameRoot + '.' + @p_PropertyName + '%'
				else
					select * from
						Property_Equipment_EquipmentClass 
					where 
						EquipmentId = @v_TypeOwnerName 
					and Name like @v_PropNameRoot + '.' + @p_PropertyName + '%'

				if (@debug = 1)
					print 'delete from '
					print '   Property_EquipmentClass '
					print 'where '
					print '   EquipmentClassName = ''' + @v_TypeOwnerName  + ''''
					print 'and PropertyName like ''' + @v_PropNameRoot + '''.''' + @p_PropertyName + '%'''
					print ''

				if (Not @test = 1)		
					delete from 
						Property_EquipmentClass 
					where 
						EquipmentClassName = @v_TypeOwnerName  
					and PropertyName like @v_PropNameRoot + '.' + @p_PropertyName + '%'
				else
					select * from
						Property_EquipmentClass 
					where 
						EquipmentClassName = @v_TypeOwnerName  
					and PropertyName like @v_PropNameRoot + '.' + @p_PropertyName + '%'
					
				
				if (@debug = 1)
					print 'UPDATE EquipmentClass '
					print 'SET Version = (SELECT MAX(Version)+1 '
					print '				  FROM EquipmentClass '
					print '				  WHERE EquipmentClassName = ''' +@v_TypeOwnerName +')'
					print 'WHERE EquipmentClassName = ''' + @v_TypeOwnerName + ''''
					print ''
				
				if (Not @test = 1)		
					-----------------------------------------------------------------
					-- Update EquipmentClass record for Equipment to bump the version
					--
					UPDATE EquipmentClass 
					SET Version = (SELECT MAX(Version)+1 
								  FROM EquipmentClass 
								 WHERE EquipmentClassName = @v_TypeOwnerName)
					WHERE EquipmentClassName = @v_TypeOwnerName
				
			end
		else
			begin
			
				--------------------------------------------------------------------------------------
				-- DELETE the property from ancestor-class (Recursive Call to Delete stored procedure)
				--
				set @v_LocalClassId = NULL
			
				select 
					@v_LocalClassId =  Id
				from
					EquipmentClass 
				where 
					EquipmentClassName = @v_TypeOwnerName
					
				if (Not @v_LocalClassId IS NULL)
				begin

					set @v_LocalPropName = @v_PropNameRoot + '.' + @p_PropertyName
					
					if (@debug = 1)
						print 'exec usp_EquipmentClassDeleteProperty ''' + 
							convert(varchar(36),@v_LocalClassId) + ''',''' +  
							@v_LocalPropName + ''''
					
					exec usp_EquipmentClassDeleteProperty
						@v_LocalClassId,
						@v_LocalPropName,
						@debug,
						@test
						
				end
			
			end         
 
    end

	--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

	--------------------------------------
	-- DELETE property from original class
	--
	if (@debug = 1)
		print 'delete from '
		print '    Property_EquipmentClass '
		print 'where '
		print '    EquipmentClassName = ''' + @v_EquipmentClassName + ''''
		print 'and PropertyName like ''' + @p_PropertyName + '%'''
		print ''

	if (Not @test = 1)		
		delete from 
			Property_EquipmentClass 
		where 
			EquipmentClassName =  @v_EquipmentClassName  
		and PropertyName like @p_PropertyName + '%'
	else
		select * from
			Property_EquipmentClass 
		where 
			EquipmentClassName =  @v_EquipmentClassName  
		and PropertyName like @p_PropertyName + '%'

	if (@debug = 1)
		print 'UPDATE EquipmentClass '
		print 'SET Version = (SELECT MAX(Version) + 1 '
		print '				  FROM EquipmentClass '
		print '				  WHERE EquipmentClassName = ''' + @v_EquipmentClassName + ')'
		print 'WHERE EquipmentClassName = ''' + @v_EquipmentClassName +  ''''
		print ''

	if (Not @test = 1)		
		---------------------------------------------------
		-- Update EquipmentClass record to bump the version
		--
		UPDATE EquipmentClass 
		SET Version = (SELECT MAX(Version)+1 
					  FROM EquipmentClass 
					 WHERE EquipmentClassName = @v_EquipmentClassName)
		WHERE EquipmentClassName = @v_EquipmentClassName
		

	
	--------------------------------------------------------------
	-- DELETE property-class association on StructuredTypeProperty 
	--
	if (@debug = 1)
		print 'delete from '
		print '    StructuredTypeProperty '
		print 'where  '
		print '	   TypeOwnerName = ''' + @v_EquipmentClassName + ''''
		print 'and Name like ''' + @p_PropertyName + '%'''
		print ''
		
	if (Not @test = 1)		
		delete from 
			StructuredTypeProperty 
		where 
			TypeOwnerName = @v_EquipmentClassName 
		and Name like @p_PropertyName + '%'
	else
		select * from
			StructuredTypeProperty 
		where 
			TypeOwnerName = @v_EquipmentClassName 
		and Name like @p_PropertyName + '%'

	IF (@trancount = 0)
	BEGIN
		IF (@debug = 1) PRINT @v_ProcName + 'Committing ...'
		COMMIT
	END

END try
BEGIN catch
	DECLARE 
		@error   INT, 
		@message VARCHAR(4000),
		@xstate  INT
	SELECT @error   = ERROR_NUMBER(),
		   @message = ERROR_MESSAGE(),
		   @xstate  = XACT_STATE()
	IF (@xstate = -1)
	BEGIN
		if(@debug = 1) print @v_ProcName + 'rollback... (@xstate = -1)'
		ROLLBACK
	END
	IF (@xstate = 1 AND @trancount = 0)
	BEGIN
		if(@debug = 1) print @v_ProcName + 'rollback...(@xstate = 1 AND @trancount = 0)'
		ROLLBACK
	END
	IF (@xstate = 1 AND @trancount > 0)
	BEGIN
		if(@debug = 1) print @v_ProcName + 'rollback...  (@xstate = 1 AND @trancount > 0)'
		ROLLBACK TRANSACTION @v_ProcName
	END;
	RAISERROR('%s: %d: %s',16,1, @v_ProcName, @error, @message)
END catch