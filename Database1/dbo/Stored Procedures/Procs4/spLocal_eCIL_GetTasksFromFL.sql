CREATE PROCEDURE [dbo].[spLocal_eCIL_GetTasksFromFL]
/*
-------------------------------------------------------------------------------------------------
Stored Procedure	:		spLocal_eCIL_GetTasksFromFL
Author				:		Linda Hudon	 STICORP
Date Created		:		13-Oct-2009
SP Type				:			
Editor Tab Spacing	:		3
Description:
=========
Get all eCIL tasks information for the Functional location we received in parameters
CALLED BY:  eCIL Web Application
Revision 		Date			Who					What
========		=====			====				=====
1.0.0			13-Oct-2009		Linda Hudon			SP Creation
1.0.1			15-Jun-2010		PD Dubois			Modify the way to get @LineIds, @MasterIds, @SlaveIds and @GroupIds
1.0.2			03-Aug-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
1.0.3			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.0.4 			03-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
1.0.5			03-Aug-2023		Payal Gadhvi			Updated SP with version management and to meet coding standard
Test Call :
exec spLocal_eCIL_GetTasksFromFL @FlList = 'DICG-153-022,DICG-153-130', @VarList = ''
spLocal_eCIL_GetTasksFromFL 'eCIL1-002-006',NULL
*/
@FlList			VARCHAR(8000),
@VarList		VARCHAR(8000)

AS
SET NOCOUNT ON;

DECLARE  @FL TABLE(
RowId			INT IDENTITY(1,1),
FLDesc			VARCHAR(50));

DECLARE
@FlDesc			VARCHAR(50),
@NbrRows		INT,
@CurrentRow		INT,
@CurrentFL		VARCHAR(50),
@NbrFL			INT,
@Fl1			VARCHAR(50),
@Fl2			VARCHAR(50),
@Fl3			VARCHAR(50),
@Fl4			VARCHAR(50),
@LineIds		VARCHAR(8000),
@MasterIds		VARCHAR(8000),
@SlaveIds		VARCHAR(8000),
@GroupIds		VARCHAR(8000);

DECLARE @ProdLines TABLE(
PlId			INT,
PlDesc			VARCHAR(50));

DECLARE @MasterUnit TABLE(
PuId			INT,
PuDesc			VARCHAR(50));

DECLARE @SlaveUnit TABLE(
PuId			INT,
PuDesc			VARCHAR(50));

DECLARE @PuGroup TABLE(
PugId			INT,
PugDesc			VARCHAR(50));

INSERT @FL (FLDesc)
	SELECT	String 
	FROM		dbo.fnLocal_STI_Cmn_SplitString(@FlList, ',');

SET @CurrentRow = 1;
SET @NbrRows = (SELECT COUNT(1) FROM @FL);

WHILE @CurrentRow <= @NbrRows
	BEGIN
		
		SET @FlDesc	= (SELECT FLDesc FROM @FL WHERE RowId = @CurrentRow);
		SET @NbrFL = (SELECT COUNT(*) FROM dbo.fnLocal_STI_Cmn_SplitString(@FlDesc,'-') );

		SET @FL1	=(SELECT STRING FROM dbo.fnLocal_STI_Cmn_SplitString(@FlDesc, '-')	WHERE ID = 1) ;		
		SET @Fl2	=(SELECT STRING FROM dbo.fnLocal_STI_Cmn_SplitString(@FlDesc, '-')	WHERE ID = 2) ; 
		SET @FL3	=(SELECT STRING FROM dbo.fnLocal_STI_Cmn_SplitString(@FlDesc, '-')	WHERE ID = 3) ;
		SET @FL4	=(SELECT STRING FROM dbo.fnLocal_STI_Cmn_SplitString(@FlDesc, '-')	WHERE ID = 4) ;
		IF @NbrFL = 1
			BEGIN
				INSERT @ProdLines
					(
					PlId, 
					PlDesc
					)
					SELECT	Id,	Description 
					FROM		dbo.fnLocal_eCIL_GetPlantModelItemByUDP	(
																						@Fl1,
																						NULL, 
																						NULL, 	
																						NULL
																						) ;			
			END
		ELSE	
			BEGIN
				IF @NbrFL = 2
					BEGIN
						INSERT @MasterUnit
							(
							PuId, 
							PuDesc
							)
							SELECT	Id,	Description 
							FROM		dbo.fnLocal_eCIL_GetPlantModelItemByUDP	(
																								@Fl1,
																								@FL2,
																								NULL,
																								NULL
																								);
						END
					ELSE
						BEGIN
							IF @NbrFL = 3
								BEGIN
									INSERT @SlaveUnit
										(
										PuId, 
										PuDesc
										)
										SELECT	Id, Description 
										FROM		dbo.fnLocal_eCIL_GetPlantModelItemByUDP	(
																											@Fl1,
																											@FL2,
																											@FL3,
																											NULL
																											);
								END
							ELSE
								BEGIN
									IF @NbrFL = 4
										BEGIN
											INSERT @PuGroup
												(
												PugId, 
												PugDesc
												)
												SELECT	Id, Description 
												FROM		dbo.fnLocal_eCIL_GetPlantModelItemByUDP	(
																													@Fl1,
																													@FL2,
																													@FL3,
																													@FL4
																													);
										END
								END
						END
				END
		SET @CurrentRow = @CurrentRow + 1;
	END

/*-- SELECT must be used instead of SET in that case because the goal is to concatenant multiple rows into a single string*/
SELECT @LineIds	=	COALESCE(@LineIds + ', ', '') + CONVERT(VARCHAR(50), PlID)
FROM	@ProdLines;
 
SELECT @MasterIds =	COALESCE(@MasterIds + ', ', '') +  CONVERT(VARCHAR(50), PuId)
FROM	@MasterUnit;

SELECT @SlaveIds =	COALESCE(@SlaveIds + ', ', '') +  CONVERT(VARCHAR(50), PuId)
FROM	@SlaveUnit;

SELECT @GroupIds =	COALESCE(@GroupIds + ', ', '') + CONVERT(VARCHAR(50), PugId)
FROM	@PuGroup;

EXEC dbo.spLocal_eCIL_TasksManagement	NULL,
													@LineIds,
													@MasterIds,
													@SlaveIds,
													@GroupIds,
													@VarList;

