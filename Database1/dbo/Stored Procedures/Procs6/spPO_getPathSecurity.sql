
CREATE Procedure [dbo].[spPO_getPathSecurity]
    @User_Id bigint,
    @Path_Id bigint,
    @PP_Id bigint
AS
    If (@PP_Id is not null)
        BEGIN

            DECLARE @TempPathId INT, @Old_Process_Order nvarchar(100)
            Select @TempPathId = pp.Path_Id, @Old_Process_Order = pp.Process_Order from Production_Plan pp where PP_Id = @PP_Id

            IF(@TempPathId is null AND @Old_Process_Order is not null)
                BEGIN
                    SELECT @TempPathId = -1;
                end

            If(@TempPathId is null)
                BEGIN
                    SELECT Error = 'ERROR: Process Order not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderNotFound', PropertyName1 = 'PP_Id', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @PP_Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END
            If(@Path_Id is null)
                BEGIN
                    Select @Path_Id = @TempPathId
                end
            If (@Path_Id is not null AND @Path_Id != @TempPathId)
             BEGIN
                 SELECT Error = 'ERROR: Process Order not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderNotFound', PropertyName1 = 'PP_Id', PropertyName2 = 'Path_Id', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @PP_Id, PropertyValue2 = @Path_Id, PropertyValue3 = '', PropertyValue4 = ''
                 RETURN
             end

        end

    if (@Path_Id is not null AND @Path_Id != -1) and (NOT EXISTS(SELECT 1 FROM Prdexec_Paths WHERE @Path_Id = Path_Id))
        BEGIN
            SELECT Error = 'ERROR: Path not found', Code = 'ResourceNotFound', ErrorType = 'PathNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END
    IF NOT EXISTS(SELECT 1 FROM Users_Base WHERE User_id = @User_Id )
        BEGIN
            SELECT Error = 'ERROR: Valid User Required', Code = 'InsufficientPermission', ErrorType = 'ValidUserNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END



DECLARE @AllPaths Table (Path_Id Int)
DECLARE @End Int, @Start Int, @PathIdIterator Int, @ActualSecurity Int, @UsersSecurity Int, @Sheet_IdIterator Int

DECLARE @DisplayOptions TABLE (Id Int Identity (1,1), Path_Id Int, Path_Desc nVarchar(1000), Sheet_Id Int, ReadSecurity Int, AddSecurity Int, DeleteSecurity Int, EditSecurity Int, ArrangeSecurity Int, OtherUsersCommentChangeSecurity INT,  UnbindStatusChangeSecurity INT
,UserSecurity int)

Insert into @AllPaths (Path_Id) Select Path_Id
from   Prdexec_Paths
where  ((@Path_Id is null OR @Path_Id = -1) or (@Path_Id = Path_Id))




    IF NOT EXISTS(SELECT 1 FROM @AllPaths)
        BEGIN
            RETURN
        END

INSERT INTO @DisplayOptions(Path_Id, Path_Desc, Sheet_Id, ReadSecurity, AddSecurity, DeleteSecurity, EditSecurity, ArrangeSecurity, OtherUsersCommentChangeSecurity, UnbindStatusChangeSecurity)
    SELECT Distinct AP.Path_Id,Prdexec_Paths.Path_Desc, SP.Sheet_Id,0,0,0,0,0,0,0
    FROM @AllPaths AP
    JOIN Prdexec_Paths on Prdexec_Paths.Path_Id = AP.Path_Id
    JOIN Sheet_Paths SP on Prdexec_Paths.Path_Id = SP.Path_Id
    JOIN Sheets s on s.Sheet_Id = sp.Sheet_Id and s.Is_Active = 1
	 
	UPDATE @DisplayOptions SET UserSecurity = dbo.fnPO_UserAccessLevel(Path_Id,@User_Id, Sheet_Id)
	UPDATE @DisplayOptions SET OtherUsersCommentChangeSecurity =  dbo.fnCMN_GetCommentsSecurity(Sheet_Id, @User_Id)
	Select * Into #Sheet_Type_Display_Options from Sheet_Type_Display_Options where Sheet_Type_Id =17 and Display_Option_Id in (8,7,46,45,404)
	
	
	;WITH 
	 
	S1 AS 
	(
		Select 
  			  Ac.Sheet_Id,Path_Id,b.Display_Option_Desc,MAX(CAST(ISNULL(SDO.Value,Display_option_default) as INT)) Value
		from 
  			#Sheet_Type_Display_Options A
			JOIN display_Options b on b.Display_Option_Id = a.Display_Option_Id
  			Join @DisplayOptions Ac On 17 = A.Sheet_Type_Id
			LEFT JOIN Sheet_Display_options SDO ON SDO.Sheet_Id = Ac.Sheet_Id ANd SDO.Display_Option_Id = A.Display_Option_Id
		WHERE a.Display_Option_Id in (8,7,46,45,404)
			Group BY Ac.Sheet_Id,Path_Id,b.Display_Option_Desc
	)
	,S AS 
	(
		Select 
  				Path_Id,sheet_Id,[DeleteSecurity],[AddSecurity],[ArrangeSecurity],[EditSecurity],[Allow Unbound Status Change]
		from 
  				S1
  				PIVOT 
  				(
  	    	    				AVG([Value]) FOR Display_Option_Desc in 
  	    	    				(
  	    	    	    				[DeleteSecurity],[AddSecurity],[ArrangeSecurity],[EditSecurity],[Allow Unbound Status Change]
  	    	    				)
  				)pvt
	)
	UPDATE DO 
	SET  
		ReadSecurity				= CASE WHEN DO.UserSecurity > 0 THEN 1 ELSE 0 END ---need to code for Unbound things
		,AddSecurity				= CASE WHEN UserSecurity >= ISNULL(S.[AddSecurity],4) THEN 1 ELSE 0 END --default is 4
		,DeleteSecurity				= CASE WHEN UserSecurity >= ISNULL(S.[DeleteSecurity],4) THEN 1 ELSE 0 END --default is 4
		,EditSecurity				= CASE WHEN UserSecurity >= ISNULL(S.[EditSecurity],4) THEN 1 ELSE 0 END --default is 4
		,ArrangeSecurity			= CASE WHEN UserSecurity >= ISNULL(S.[ArrangeSecurity],3) THEN 1 ELSE 0 END --default is 3
		,UnbindStatusChangeSecurity = CASE WHEN ISNULL(S.[Allow Unbound Status Change],1) >=1 THEN 1 ELSE 0 END  
	from 
		S 
		Join @DisplayOptions DO on DO.Sheet_Id = S.Sheet_Id AND DO.Path_Id = S.Path_Id	
	

DECLARE @UnboundRead INT = 0, @UnboundAdd INT = 0, @UnboundDelete INT = 0, @UnboundEdit INT = 0, @UnboundArrangeSecurity INT = 0, @UnboundeOtherUsersCommentChangeSecurity INT = 0, @UnboundUnbindStatusChangeSecurity INT = 0
select @End = max(Id) from @DisplayOptions
IF(@End > 0)
    BEGIN
        -- If there are some path then we will select minimum security for unbounded. If there are no paths, we will select zero permission for unbounded
        Select @UnboundRead = 1; Select @UnboundAdd = 1; Select @UnboundDelete = 1; Select @UnboundEdit = 1; Select @UnboundArrangeSecurity = 1; Select @UnboundeOtherUsersCommentChangeSecurity = 1; Select @UnboundUnbindStatusChangeSecurity = 1;
    end
	/*
SET @Start = 1
    WHILE @Start <= @End
        BEGIN
            SELECT @PathIdIterator = Path_Id From @DisplayOptions WHERE Id = @Start
            SELECT @Sheet_IdIterator = Sheet_Id From @DisplayOptions where Id = @Start

            SELECT @UsersSecurity = dbo.fnPO_UserAccessLevel(@PathIdIterator,@User_Id, @Sheet_IdIterator)
            DECLARE @TempReadSecurity INT;
            Select @TempReadSecurity = Case When @UsersSecurity > 0 Then 1 else 0 end
            Update @DisplayOptions SET ReadSecurity  = @TempReadSecurity WHERE Path_Id =  @PathIdIterator AND Sheet_Id = @Sheet_IdIterator
            if(@TempReadSecurity < @UnboundRead ) Select @UnboundRead = @TempReadSecurity

            SELECT @ActualSecurity = dbo.fnPO_CheckSheetSecurity(@PathIdIterator,8,4,@UsersSecurity, @Sheet_IdIterator)
            Update @DisplayOptions SET AddSecurity  = @ActualSecurity WHERE Path_Id =  @PathIdIterator  AND Sheet_Id = @Sheet_IdIterator
            if(@ActualSecurity < @UnboundAdd) Select @UnboundAdd = @ActualSecurity

            SELECT @ActualSecurity = dbo.fnPO_CheckSheetSecurity(@PathIdIterator,7,4,@UsersSecurity, @Sheet_IdIterator)
            Update @DisplayOptions SET DeleteSecurity  = @ActualSecurity WHERE Path_Id =  @PathIdIterator AND Sheet_Id = @Sheet_IdIterator
            if(@ActualSecurity < @UnboundDelete) Select @UnboundDelete = @ActualSecurity


            SELECT @ActualSecurity = dbo.fnPO_CheckSheetSecurity(@PathIdIterator,46,4,@UsersSecurity, @Sheet_IdIterator)
            Update @DisplayOptions SET EditSecurity  = @ActualSecurity WHERE Path_Id =  @PathIdIterator AND Sheet_Id = @Sheet_IdIterator
            if(@ActualSecurity < @UnboundEdit) Select @UnboundEdit = @ActualSecurity


            SELECT @ActualSecurity = dbo.fnPO_CheckSheetSecurity(@PathIdIterator,45,3,@UsersSecurity, @Sheet_IdIterator)
            Update @DisplayOptions SET ArrangeSecurity  = @ActualSecurity WHERE Path_Id =  @PathIdIterator AND Sheet_Id = @Sheet_IdIterator
            if(@ActualSecurity < @UnboundArrangeSecurity) Select @UnboundArrangeSecurity = @ActualSecurity


            SELECT @ActualSecurity = dbo.fnCMN_GetCommentsSecurity(@Sheet_IdIterator, @User_Id)
            Update @DisplayOptions SET OtherUsersCommentChangeSecurity  = @ActualSecurity WHERE Path_Id =  @PathIdIterator AND Sheet_Id = @Sheet_IdIterator
            if(@ActualSecurity < @UnboundeOtherUsersCommentChangeSecurity) Select @UnboundeOtherUsersCommentChangeSecurity = @ActualSecurity

            -- If the user has OtherUserCommentSecurity then he will be able to add/update/delete other users comments as well

            SELECT @ActualSecurity = dbo.fnPO_CheckSheetSecurity(@PathIdIterator,404,1,1, @Sheet_IdIterator)
            Update @DisplayOptions SET UnbindStatusChangeSecurity  = @ActualSecurity WHERE Path_Id =  @PathIdIterator AND Sheet_Id = @Sheet_IdIterator
            if(@ActualSecurity < @UnboundUnbindStatusChangeSecurity) Select @UnboundUnbindStatusChangeSecurity = @ActualSecurity


            SET @Start = @Start + 1
        END

		*/

		

		  

IF(@Path_Id is not null AND NOT EXISTS (Select 1 from @DisplayOptions))
BEGIN
    -- If it comes here then this path is there in thick client but it is not attached to any active sheets. In this scenario we should restrict all the permissions on this path
    Select Path_Id = @Path_Id, pp.Path_Desc as Path_Desc, 0 as 'ReadSecurity', 0 as 'AddSecurity', 0 as 'DeleteSecurity', 0 as 'EditSecurity', 0 as 'ArrangeSecurity',
           0 as 'CommentReadSecurity', 0 as 'CommentAddSecurity', 0 as 'CommentDeleteSecurity', 0 as 'CommentEditSecurity', 0 as 'OtherUsersCommentChangeSecurity', 0 as 'UnbindSecurity'
    from Prdexec_Paths pp where pp.Path_Id = @Path_Id
end
ELSE IF(@Path_Id = -1 AND NOT EXISTS (Select 1 from @DisplayOptions))
    BEGIN
        Select Path_Id = @Path_Id, 'Unbound' as Path_Desc, 0 as 'ReadSecurity', 0 as 'AddSecurity', 0 as 'DeleteSecurity', 0 as 'EditSecurity', 0 as 'ArrangeSecurity',
                         0 as 'CommentReadSecurity', 0 as 'CommentAddSecurity', 0 as 'CommentDeleteSecurity', 0 as 'CommentEditSecurity', 0 as 'OtherUsersCommentChangeSecurity', 0 as 'UnbindStatusChangeSecurity'
    end
ELSE
BEGIN

    -- Inserting unbounded path security
    INSERT INTO @DisplayOptions(Path_Id, Path_Desc, Sheet_Id, ReadSecurity, AddSecurity, DeleteSecurity, EditSecurity, ArrangeSecurity, OtherUsersCommentChangeSecurity, UnbindStatusChangeSecurity) Values (-1, 'Unbound', null, @UnboundRead, @UnboundAdd, @UnboundDelete, @UnboundEdit, @UnboundArrangeSecurity, @UnboundeOtherUsersCommentChangeSecurity, @UnboundUnbindStatusChangeSecurity)
    
	;WITH MINVals as (Select MIN(ReadSecurity)ReadSecurity, MIN(AddSecurity)AddSecurity, MIN(DeleteSecurity) DeleteSecurity,MIN(EditSecurity) EditSecurity,MIN(ArrangeSecurity) ArrangeSecurity, 
		 MIN(OtherUsersCommentChangeSecurity)OtherUsersCommentChangeSecurity,MIN(UnbindStatusChangeSecurity) UnbindStatusChangeSecurity from @DisplayOptions WHERE Path_Id >-1)
		 UPDATE @DisplayOptions 
		 SET 
			ReadSecurity = (Select ReadSecurity from MINVals), 
			AddSecurity = (Select AddSecurity from MINVals), 
			DeleteSecurity = (Select DeleteSecurity from MINVals), 
			EditSecurity = (Select EditSecurity from MINVals), 
			ArrangeSecurity = (Select ArrangeSecurity from MINVals), 
			OtherUsersCommentChangeSecurity = (Select OtherUsersCommentChangeSecurity from MINVals), 
			UnbindStatusChangeSecurity = (Select UnbindStatusChangeSecurity from MINVals)
		 WHERE Path_Id =-1
	-- deleting all the other details if only pathId -1 i.e unbound security is requested
    IF(@Path_Id is not null)
        BEGIN
            DELETE from @DisplayOptions where Path_Id <> @Path_Id
        end
    Select Path_Id, Path_Desc, Min(ReadSecurity) as 'ReadSecurity', Min(AddSecurity) as 'AddSecurity', Min(DeleteSecurity) as 'DeleteSecurity', Min(EditSecurity) as 'EditSecurity', MIN(ArrangeSecurity) as 'ArrangeSecurity',
           Min(ReadSecurity) as 'CommentReadSecurity',Min(ReadSecurity) as 'CommentAddSecurity', Min(ReadSecurity) as 'CommentEditSecurity', Min(ReadSecurity) as 'CommentDeleteSecurity',  Min(OtherUsersCommentChangeSecurity) as 'OtherUsersCommentChangeSecurity', Min(UnbindStatusChangeSecurity) as 'UnbindStatusChangeSecurity'
    from @DisplayOptions Group By Path_Id, Path_Desc

end




