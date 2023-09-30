Create Procedure dbo.spDAML_AddPath
 	 @PLId 	  	  	  	  	 int,
 	 @PathCode 	  	  	  	 varchar(50),
 	 @PathDesc 	  	  	  	 varchar(50),
 	 @IsScheduleControled 	 bit,
 	 @ScheduleControlType 	 tinyint,
 	 @IsLineProduction 	  	 bit,
 	 @CreateChildren 	  	  	 bit,
 	 @UserId 	  	  	  	  	 int,
 	 @PathId 	  	  	  	  	 int output
AS
declare @Status int
exec @Status = spEMEPC_PutExecPaths @PLId, @PathDesc, @PathCode, @IsScheduleControled, @ScheduleControlType, @IsLineProduction, @CreateChildren, @UserId, @PathId output
if (@Status <> 0)
 	 select @PathId = 0
