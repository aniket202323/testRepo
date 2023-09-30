
CREATE PROCEDURE dbo.spPO_ModifyStatusDetails
@PP_Status_Id			int = null	-- Status Id fro update
,@StatusGroup nvarchar(400) = null -- Status Group
,@StatusOrder int = null -- Status Order
,@User_Id int = null
AS

    IF @PP_Status_Id IS NULL OR NOT EXISTS (SELECT 1 from Production_Plan_Statuses where PP_Status_Id = @PP_Status_Id)
        BEGIN
            SELECT Error = 'ERROR: Status not found', Code = 'InvalidData', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'StatusId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @PP_Status_Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END

    IF NOT EXISTS(SELECT 1 FROM Users_Base WHERE User_id = @User_Id )
        BEGIN
            SELECT Error = 'ERROR: Valid User Required', Code = 'InsufficientPermission', ErrorType = 'ValidUserNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END

    -- Only user with administrator group and admin access is allowed for this update
    IF NOT EXISTS (SELECT 1 FROM User_Security WHERE User_Id = @User_Id  and Group_Id = 1 and Access_Level = 4)
        BEGIN
            SELECT Error = 'ERROR: User does not have access to modify status details. Only users with admin access in administrator group are allowed', Code = 'InsufficientPermission', ErrorType = 'InsufficientAccessLevel', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        end


DECLARE @Insert_Id integer
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
VALUES (1,@User_Id,'spPO_ModifyStatusDetails',
        Convert(nVarChar(10),@PP_Status_Id) + ','  +
        Convert(nVarChar(10),@StatusGroup) + ','  +
        Convert(nVarChar(10),@StatusOrder) + ','  +
        Convert(nVarChar(10),@User_Id),
        dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()


Update Production_Plan_Statuses set Status_Group = @StatusGroup, Status_Order = @StatusOrder where PP_Status_Id = @PP_Status_Id



UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id




