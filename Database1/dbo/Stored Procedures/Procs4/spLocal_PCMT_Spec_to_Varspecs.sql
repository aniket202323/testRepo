














-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Spec_to_Varspecs]
/*
-------------------------------------------------------------------------------------------------

Updated By	:	Patrick-Daniel Dubois (System Technologies for Industry Inc)
Date			:	2008-04-30
Version		:	1.2.0
Purpose		: 	Reset parent variables to null at the begining of loop
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-01-11
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					QSMT Version 10.0.0
-------------------------------------------------------------------------------------------------
Created by	:	Ugo Lapierre, Solution et Technologies Industrielles Inc.
On				:	31-jul-03
Version		:	1.0.0
Purpose		:	This SP get info from active_specs and push it into var_specs.  It should be
					run after a product has been attached to a characteristic.
-------------------------------------------------------------------------------------------------
*/

@pu_id				INT,
@Prod_Id				INT,
@Char_Id				INT,
@Effective_Date	datetime

AS
SET NOCOUNT ON

DECLARE 
@Prop_Id							INT,
@@Var_Id							INT,
@@Spec_Id						INT,
@Parent_Char_Id				INT,
@Parent_AS_Id					INT,
@Parent_U_Entry 				varchar(25), 
@Parent_U_Reject 				varchar(25), 
@Parent_U_Warning 			varchar(25), 
@Parent_U_User					varchar(25), 
@Parent_Target					varchar(25), 
@Parent_L_User					varchar(25), 
@Parent_L_Warning				varchar(25), 
@Parent_L_Reject				varchar(25), 
@Parent_L_Entry				varchar(25),
@Parent_Test_Freq 			INT,
@Parent_Effective_Date		datetime,
@Parent_Expiration_Date		datetime,
@Child_VS_Id					INT,
@Child_AS_Id					INT,
@Child_U_Entry 				varchar(25), 
@Child_U_Reject 				varchar(25), 
@Child_U_Warning 				varchar(25), 
@Child_U_User					varchar(25), 
@Child_Target					varchar(25), 
@Child_L_User					varchar(25), 
@Child_L_Warning				varchar(25), 
@Child_L_Reject				varchar(25), 
@Child_L_Entry					varchar(25),
@Child_Test_Freq 				INT,
@Child_Effective_Date		datetime,
@Child_Expiration_Date		datetime,
@Child_Is_Defined				INT,
@Level_Num						INT,
@pu_desc							varchar(30),
@Char								varchar(30),
@counter							INT,
@intVarTableCount				INTEGER,
@intVarCount					INTEGER

DECLARE @Variables TABLE(
	item_id	INTEGER IDENTITY(1,1),
	var_id	INTEGER,
	spec_id	INTEGER
)

SET @effective_date = GETDATE()
SET @pu_desc = (SELECT pu_desc FROM dbo.prod_units WHERE pu_id = @pu_id)
SET @char = (SELECT char_desc FROM characteristics WHERE char_id = @Char_Id)

-- Get the property id for for the characteristics
SET @prop_id = (SELECT Prop_id FROM dbo.characteristics WHERE char_id = @Char_Id)

IF @prop_id IS NULL
	BEGIN
		RETURN
	END

--Fetch through all variables on the units where a spec variable is from the previous property
--DECLARE VarCursor CURSOR FOR

INSERT @Variables (var_id, spec_id)
SELECT	v.var_id,v.spec_id
FROM		dbo.variables v 
JOIN		dbo.specifications s ON v.spec_id = s.spec_id
WHERE		v.pu_id = @pu_id
AND		s.prop_id = @prop_id

SET @intVarTableCount = (SELECT MAX(item_id) FROM @Variables)

SELECT @intVarCount = 1
SELECT @@var_id = var_id, @@spec_id = spec_id FROM @Variables WHERE item_id = @intVarCount

WHILE @intVarCount <= @intVarTableCount BEGIN

--OPEN VarCursor
--FETCH NEXT FROM VarCursor
--INTO @@var_id,@@spec_id

--WHILE @@FETCH_STATUS = 0
--	BEGIN
		/******************************************************************
		* 						Get Parent Central Specs	 							*
		*******************************************************************/

		SET		@Parent_AS_Id				= NULL
		SET		@Parent_U_Entry 			= NULL
		SET		@Parent_U_Reject 			= NULL
		SET		@Parent_U_Warning			= NULL
		SET		@Parent_U_User				= NULL
		SET		@Parent_Target				= NULL
		SET		@Parent_L_User				= NULL
		SET		@Parent_L_Warning			= NULL
		SET		@Parent_L_Reject			= NULL
		SET		@Parent_L_Entry			= NULL
		SET		@Parent_Test_Freq 		= NULL
		SET		@Parent_Effective_Date		= NULL

		SELECT	@Parent_AS_Id				= AS_Id,
					@Parent_U_Entry 			= U_Entry,
					@Parent_U_Reject 			= U_Reject,
					@Parent_U_Warning			= U_Warning,
					@Parent_U_User				= U_User,
					@Parent_Target				= Target,
					@Parent_L_User				= L_User,
					@Parent_L_Warning			= L_Warning,
					@Parent_L_Reject			= L_Reject,
					@Parent_L_Entry			= L_Entry,
					@Parent_Test_Freq 		= Test_Freq,
					@Parent_Effective_Date	= Effective_Date
		FROM		dbo.Active_Specs
		WHERE		Spec_Id = @@Spec_Id
		AND		Char_Id = @Char_Id
		AND		Effective_Date <= @Effective_Date
		AND		(
					Expiration_Date > @Effective_Date
					OR
					Expiration_Date IS NULL
					)

		IF @Parent_AS_Id > 0
			BEGIN
			/******************************************************************
			* 	   Assign to child variable specs for each related product	   *
			*******************************************************************/
			SET	@Child_VS_Id 				= NULL
			SET	@Child_AS_Id				= NULL
			SET	@Child_U_Entry 			= NULL
			SET	@Child_U_Reject 			= NULL
			SET	@Child_U_Warning			= NULL
			SET	@Child_U_User				= NULL
			SET	@Child_Target				= NULL
			SET	@Child_L_User				= NULL
			SET	@Child_L_Warning			= NULL
			SET	@Child_L_Reject			= NULL
			SET	@Child_L_Entry				= NULL
			SET	@Child_Test_Freq 			= NULL
			SET	@Child_Effective_Date	= NULL
			SET	@Child_Is_Defined			= NULL

			SELECT	@Child_VS_Id 				= VS_Id, 
						@Child_AS_Id				= AS_Id,
						@Child_U_Entry 			= U_Entry,
						@Child_U_Reject 			= U_Reject,
						@Child_U_Warning 			= U_Warning,
						@Child_U_User				= U_User,
						@Child_Target				= Target,
						@Child_L_User				= L_User,
						@Child_L_Warning			= L_Warning,
						@Child_L_Reject			= L_Reject,
						@Child_L_Entry				= L_Entry,
						@Child_Test_Freq 			= Test_Freq,
						@Child_Effective_Date	= Effective_Date,
						@Child_Is_Defined			= Is_Defined
	  		FROM		dbo.Var_Specs
	  		WHERE		Var_Id = @@Var_Id
	  		AND		Prod_Id = @Prod_Id
	  		AND		Effective_Date <= @Effective_Date
	  		AND		(
	  					Expiration_Date > @Effective_Date
	  					OR
	  					Expiration_Date IS NULL
	  					)
	  					
			-- If the Child_AS_Id is null then must calculated it to change it to an override
			IF @Child_AS_Id IS NULL
				BEGIN
					-- Calculate bit mask
					SET @Child_Is_Defined = 0
					
					IF @Child_Test_Freq IS NOT NULL
						SELECT @Child_Is_Defined = @Child_Is_Defined + 512
						
					IF @Child_U_Entry IS NOT NULL
						SELECT @Child_Is_Defined = @Child_Is_Defined + 256
						
					IF @Child_U_Reject IS NOT NULL 
						SELECT @Child_Is_Defined = @Child_Is_Defined + 128
						
					IF @Child_U_Warning IS NOT NULL
						SELECT @Child_Is_Defined = @Child_Is_Defined + 64
						
					IF @Child_U_User IS NOT NULL
						SELECT @Child_Is_Defined = @Child_Is_Defined + 32
						
					IF @Child_Target IS NOT NULL
						SELECT @Child_Is_Defined = @Child_Is_Defined + 16
						
					IF @Child_L_User IS NOT NULL
						SELECT @Child_Is_Defined = @Child_Is_Defined + 8
						
					IF @Child_L_Warning IS NOT NULL
						SELECT @Child_Is_Defined = @Child_Is_Defined + 4
						
					IF @Child_L_Reject IS NOT NULL
						SELECT @Child_Is_Defined = @Child_Is_Defined + 2
						
					IF @Child_L_Entry IS NOT NULL
						SELECT @Child_Is_Defined = @Child_Is_Defined + 1
						
					IF @Child_Is_Defined = 0
						SELECT @Child_Is_Defined = NULL
				END		
	       
			-- Update Child Specifications with the Parent Specifications, if any
			SELECT	@Child_Test_Freq	= CASE WHEN @Child_Is_Defined & 512	> 0	THEN @Child_Test_Freq 	ELSE @Parent_Test_Freq 	END,
						@Child_U_Entry		= CASE WHEN @Child_Is_Defined & 256 > 0	THEN @Child_U_Entry 		ELSE @Parent_U_Entry 	END,
						@Child_U_Reject 	= CASE WHEN @Child_Is_Defined & 128 > 0	THEN @Child_U_Reject 	ELSE @Parent_U_Reject 	END,
						@Child_U_Warning 	= CASE WHEN @Child_Is_Defined & 64	> 0	THEN @Child_U_Warning	ELSE @Parent_U_Warning 	END,
						@Child_U_User 		= CASE WHEN @Child_Is_Defined & 32	> 0	THEN @Child_U_User 		ELSE @Parent_U_User 		END,
						@Child_Target 		= CASE WHEN @Child_Is_Defined & 16	> 0	THEN @Child_Target 		ELSE @Parent_Target 		END,
						@Child_L_User 		= CASE WHEN @Child_Is_Defined & 8	> 0	THEN @Child_L_User 		ELSE @Parent_L_User 		END,
						@Child_L_Warning 	= CASE WHEN @Child_Is_Defined & 4	> 0	THEN @Child_L_Warning 	ELSE @Parent_L_Warning 	END,
						@Child_L_Reject 	= CASE WHEN @Child_Is_Defined & 2	> 0	THEN @Child_L_Reject 	ELSE @Parent_L_Reject 	END,
						@Child_L_Entry 	= CASE WHEN @Child_Is_Defined & 1	> 0	THEN @Child_L_Entry 		ELSE @Parent_L_Entry 	END
						
			/******************************************************************
			* 		      Write or Update specification record		 		     *
			*******************************************************************/
			IF (@Child_VS_Id IS NOT NULL) AND (@Effective_Date = @Child_Effective_Date)
				BEGIN
					UPDATE	dbo.Var_Specs
					SET		Test_Freq		= @Child_Test_Freq,
								U_Entry			= @Child_U_Entry,
								U_Reject 		= @Child_U_Reject,
								U_Warning 		= @Child_U_Warning,
								U_User 			= @Child_U_User,
								Target 			= @Child_Target,
								L_User 			= @Child_L_User,
								L_Warning 		= @Child_L_Warning,
								L_Reject 		= @Child_L_Reject,
								L_Entry 			= @Child_L_Entry,
								AS_Id				= @Parent_AS_Id,
								Is_Defined		= @Child_Is_Defined
					WHERE		VS_Id = @Child_VS_Id
				END
			ELSE
				BEGIN
					-- Check for later child spec (ie.for expiration date)
					SET @Child_Expiration_Date = (
															SELECT TOP 1	Effective_Date
															FROM				dbo.Var_Specs
															WHERE				Var_Id = @@Var_Id
															AND				Prod_Id = @Prod_Id
															AND				Effective_Date > @Effective_Date
															ORDER BY			Effective_Date ASC
															)
															
					-- Insert new record  
       			INSERT dbo.Var_Specs	(
       										Var_Id, Prod_Id, L_Entry, L_Reject, L_Warning, L_User, Target, U_User, U_Warning,
       										U_Reject, U_Entry, Test_Freq, Effective_Date, Expiration_Date, Is_Defined, AS_Id
       										)
					VALUES					(
												@@Var_Id, @Prod_Id, @Child_L_Entry, @Child_L_Reject, @Child_L_Warning, @Child_L_User,
												@Child_Target, @Child_U_User, @Child_U_Warning, @Child_U_Reject, @Child_U_Entry,
												@Child_Test_Freq, @Effective_Date, @Child_Expiration_Date, @Child_Is_Defined, @Parent_AS_Id
												)
												
					SET @Child_VS_Id = @@IDENTITY
	       
					-- Expire other specifications
					UPDATE	dbo.Var_Specs
					SET		Expiration_Date = @Effective_Date
					WHERE		Var_Id = @@Var_Id
					AND		Prod_Id = @Prod_Id
					AND		Effective_Date < @Effective_Date
					AND		(
								Expiration_Date > @Effective_Date
								OR
								Expiration_Date IS NULL
								)
				END
			END

		SELECT @intVarCount = @intVarCount + 1
		SELECT @@var_id = var_id, @@spec_id = spec_id FROM @Variables WHERE item_id = @intVarCount
		    
		--FETCH NEXT FROM VarCursor
		--INTO @@var_id,@@spec_id
	
END
	
--CLOSE VarCursor
--DEALLOCATE VarCursor

SELECT 1

SET NOCOUNT OFF
















