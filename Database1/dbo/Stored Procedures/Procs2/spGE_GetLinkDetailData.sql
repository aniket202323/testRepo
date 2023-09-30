Create Procedure dbo.spGE_GetLinkDetailData
@CompId 	 int,
@DecimalSep     nvarchar(2) = '.'
 AS
Select @DecimalSep = COALESCE(@DecimalSep, '.')
Declare @TimeStamp 	   	 Datetime,
 	 @DimX 	  	  	 real,
 	 @DimY 	  	  	 real,
 	 @DimZ 	  	  	 real,
 	 @DimA 	  	  	 real,
 	 @CoordX 	  	  	 real,
 	 @CoordY 	  	  	 real,
 	 @CoordZ 	  	  	 real,
 	 @CoordA 	  	  	 real,
 	 @PEI_Id  	  	  	 Int,
 	 @EventId 	  	  	 Int,
 	 @SheetTimeStamp 	 DateTime,
 	 @SheetDesc 	  	 nvarchar(50),
 	 @SheetPU 	  	  	 Int
 Select @TimeStamp = Timestamp, @DimX = Dimension_X, @DimY = Dimension_Y, @DimZ = Dimension_Z,
 	 @DimA = Dimension_A,@CoordX = Start_Coordinate_X, @CoordY = Start_Coordinate_Y,
 	 @CoordZ = Start_Coordinate_Z,@CoordA = Start_Coordinate_A,@PEI_Id = PEI_Id,@EventId = Source_Event_Id,
 	 @SheetTimeStamp = Isnull(Timestamp,Start_Time)
 From Event_Components
  Where Component_Id = @CompId
If @PEI_Id is null
 	 Select @PEI_Id = Pei_Id from PrdExec_Input_Event_History Where Event_Id = @EventId
If @PEI_Id is null
 	 Select @SheetDesc = '<none>',@SheetTimeStamp = Null
Else
  Begin
 	 If (Select Count(*) from Sheets where PEI_Id = @PEI_Id) = 1
 	   Select @SheetDesc = Sheet_Desc,@SheetPU = Master_Unit
 	    	 From Sheets 
 	  	 Where PEI_Id = @PEI_Id
 	 Else
 	   Select @SheetDesc = s.Sheet_Desc,@SheetPU = pei.PU_Id
 	    	 From PrdExec_inputs  pei
 	     Join Sheets s on s.Sheet_Id = pei.Def_Event_Comp_Sheet_Id
 	  	 Where pei.PEI_Id = @PEI_Id
  End
SELECT FieldId = 1,[Data] = @TimeStamp
DECLARE  @HeaderData Table(Caption nvarchar(100),Data nvarchar(100),BlankSpace TinyInt,Forecolor Int)
 Insert Into @HeaderData (Caption,Data,BlankSpace,Forecolor) 
 	 Select 'TimeStamp:','|Time|',0,0
Insert Into @HeaderData (Caption,Data,BlankSpace,Forecolor) 
 	 Select 'Dimension X:',Coalesce(Convert(nvarchar(25),@DimX),'N/A'),1,0
Insert Into @HeaderData (Caption,Data,BlankSpace,Forecolor) 
 	 Select 'Dimension Y:',Coalesce(Convert(nvarchar(25),@DimY),'N/A'),0,0
Insert Into @HeaderData (Caption,Data,BlankSpace,Forecolor) 
 	 Select 'Dimension Z:',Coalesce(Convert(nvarchar(25),@DimZ),'N/A'),0,0
Insert Into @HeaderData (Caption,Data,BlankSpace,Forecolor) 
 	 Select 'Dimension A:',Coalesce(Convert(nvarchar(25),@DimA),'N/A'),0,0
Insert Into @HeaderData (Caption,Data,BlankSpace,Forecolor) 
 	 Select 'Coordinate X:',Coalesce(Convert(nvarchar(25),@CoordX),'N/A'),1,0
Insert Into @HeaderData (Caption,Data,BlankSpace,Forecolor) 
 	 Select 'Coordinate Y:',Coalesce(Convert(nvarchar(25),@CoordY),'N/A'),0,0
Insert Into @HeaderData (Caption,Data,BlankSpace,Forecolor) 
 	 Select 'Coordinate Z:',Coalesce(Convert(nvarchar(25),@CoordZ),'N/A'),0,0
Insert Into @HeaderData (Caption,Data,BlankSpace,Forecolor) 
 	 Select 'Coordinate A:',Coalesce(Convert(nvarchar(25),@CoordA),'N/A'),0,0
Select * from @HeaderData
If @SheetTimeStamp is null 
 	 Select @SheetDesc = '<none>'
SELECT @SheetDesc = isnull(@SheetDesc,'<none>')
SELECT Sheet_Desc = @SheetDesc,Timestamp = @SheetTimeStamp
