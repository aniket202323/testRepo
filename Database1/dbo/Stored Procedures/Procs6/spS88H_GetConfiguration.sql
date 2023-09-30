CREATE Procedure dbo.spS88H_GetConfiguration
@HistorianName nvarchar(100),
@ModelNumber nvarchar(50)
AS
Create Table #Configuration (
  ID int,
  Area nvarchar(100) NULL,
  Cell nvarchar(100) NULL,
  Unit nvarchar(100) NULL,
  TagPrefix nvarchar(100) NULL,
  LastTime datetime NULL,
  LastNumber int NULL
)
--Insert Into #Configuration (ID, Area, Cell, Unit, Tagprefix, LastTime, LastNumber) Values (22, 'ADPO', 'CS', 'CSMT', 'CSMT', '17-oct-02 8:50', 0)
Insert Into #Configuration (ID)
  Select ec_id 
    from event_configuration ec
    Join ed_models m on m.ed_model_id = ec.ed_model_id and m.model_num = @ModelNumber
--TODO: filter by historian when that is parameter
Declare @@Id int
Declare @Area nvarchar(100)
Declare @Cell nvarchar(100)
Declare @Unit nvarchar(100)
Declare @TagPrefix nvarchar(100)
Declare @LastTime datetime
Declare @LastNumber int
Declare MyCursor Insensitive Cursor 
  For Select ID From #Configuration
  For Read Only
Open MyCursor
Fetch Next From MyCursor Into @@Id
While @@Fetch_Status = 0
  Begin
    Select @Area = ecv.Value
      From event_configuration_values ecv
      Where ecv_id = (Select ecv_id From event_configuration_data where ec_id = @@Id and ed_field_id = 2767)
    Select @Cell = ecv.Value
      From event_configuration_values ecv
      Where ecv_id = (Select ecv_id From event_configuration_data where ec_id = @@Id and ed_field_id = 2768)
    Select @Unit = ecv.Value
      From event_configuration_values ecv
      Where ecv_id = (Select ecv_id From event_configuration_data where ec_id = @@Id and ed_field_id = 2769)
    Select @TagPrefix = ecv.Value
      From event_configuration_values ecv
      Where ecv_id = (Select ecv_id From event_configuration_data where ec_id = @@Id and ed_field_id = 2770)
    Select @LastNumber = convert(int, coalesce(convert(nvarchar(50),ecv.Value), 0))
      From event_configuration_values ecv
      Where ecv_id = (Select ecv_id From event_configuration_data where ec_id = @@Id and ed_field_id = 2771)
    Select @LastTime = convert(datetime, coalesce(convert(nvarchar(50),ecv.Value), dbo.fnServer_CmnGetDate(getUTCdate())))
      From event_configuration_values ecv
      Where ecv_id = (Select ecv_id From event_configuration_data where ec_id = @@Id and ed_field_id = 2772)
    Update #Configuration
      Set Area = @Area, Cell = @Cell, Unit = @Unit, Tagprefix = @TagPrefix, LastNumber = @LastNumber, LastTime = @LastTime
        Where Id = @@Id
    Fetch Next From MyCursor Into @@Id
  End
Close MyCursor
Deallocate MyCursor  
Select * From #Configuration
  Where TagPrefix Is Not Null
Drop Table #Configuration
