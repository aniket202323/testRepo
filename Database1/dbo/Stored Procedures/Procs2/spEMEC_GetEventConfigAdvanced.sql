Create Procedure dbo.spEMEC_GetEventConfigAdvanced
@EC_Id int,
@User_Id int,
@Extended_Info nvarchar(255) OUTPUT,
@Exclusions nvarchar(255) OUTPUT
AS
select @Extended_Info = extended_info, @Exclusions = exclusions from event_configuration
where ec_id = @EC_Id
