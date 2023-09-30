CREATE Procedure dbo.spS88H_SetProcessed
@Id int,
@LastNumber int,
@LastTime datetime
AS
Update event_configuration_values 
  set Value = convert(nvarchar(50), @LastNumber)
  Where ecv_id = (Select ecv_id From event_configuration_data where ec_id = @Id and ed_field_id = 2771)
Update event_configuration_values 
  set Value = convert(nvarchar(30), @LastTime, 109)
  Where ecv_id = (Select ecv_id From event_configuration_data where ec_id = @Id and ed_field_id = 2772)
Select Message = 'Success'
