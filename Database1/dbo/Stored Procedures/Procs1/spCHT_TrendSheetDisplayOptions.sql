Create Procedure dbo.spCHT_TrendSheetDisplayOptions 
@Sheet_Desc nvarchar(50)
As 
  Declare @SheetId int,
   	  	  	  	 @SheetType int
  Select @SheetId = Sheet_Id, @SheetType = Sheet_Type
    From Sheets
      Where Sheet_Desc = @Sheet_Desc
--*******************************************************
--** Return DisplayIOptions settings
--******************************************************
  Create Table #Display_Options (
    Id int,
    Name nvarchar(100),
    Value nvarchar(100)
    )
  Insert Into #Display_Options Values (NULL,'AFFECTALLCHARTS', 'True')
  Insert Into #Display_Options Values (NULL,'DISPLAYLIMITS','True')
  Insert Into #Display_Options Values (NULL,'DISPLAYDATAPOINTLABEL','False')
  Insert Into #Display_Options Values (NULL,'TIMESCROLLFACTOR','100')
  Insert Into #Display_Options Values (NULL,'MAXIMUMNUMBEROFVARIABLESPERCHART','5')
  Insert Into #Display_Options Values (NULL,'DISPLAYTOOLBAR','0')
  Insert Into #Display_Options Values (NULL,'TRENDMODE','0')
  Insert Into #Display_Options Values (NULL,'REALTIMEDATAPOINTINTERVAL','1')
  Insert into #Display_Options (Id, Name, Value)
  Select do.Display_Option_Id, do.Display_Option_Desc, sdo.Value
    From Sheet_Display_Options sdo
    Join Display_Options do on do.Display_Option_Id = sdo.Display_Option_Id
    Where sdo.Sheet_Id = @Sheetid and COALESCE(sdo.Value, '') <> ''
  Insert into #Display_Options (Id, Name, Value)
  Select do.Display_Option_Id, do.Display_Option_Desc, stdo.Display_Option_Default
    From Sheet_Type_Display_Options stdo
    Join Display_Options do on do.Display_Option_Id = stdo.Display_Option_Id
    Where stdo.Display_Option_Id not in (Select Id from #Display_Options WHERE ID IS not null)
      and stdo.Sheet_Type_Id = @SheetType
      and stdo.Display_Option_Default is not NULL
  Select Name, Value from #Display_Options order by Name
  Drop Table #Display_Options
