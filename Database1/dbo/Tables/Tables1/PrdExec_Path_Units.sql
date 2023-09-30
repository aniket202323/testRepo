CREATE TABLE [dbo].[PrdExec_Path_Units] (
    [PEPU_Id]             INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Is_Production_Point] BIT NOT NULL,
    [Is_Schedule_Point]   BIT NOT NULL,
    [Path_Id]             INT NOT NULL,
    [PU_Id]               INT NULL,
    [Unit_Order]          INT NULL,
    CONSTRAINT [PrdExecPathsUnits_PK_PEPUId] PRIMARY KEY CLUSTERED ([PEPU_Id] ASC),
    CONSTRAINT [PrdExec_Path_Units_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [PrdexecPathsUnits_FK_PrdExecPath] FOREIGN KEY ([Path_Id]) REFERENCES [dbo].[Prdexec_Paths] ([Path_Id])
);


GO
CREATE TRIGGER dbo.PrdExec_Path_Units_Ins 
  ON dbo.PrdExec_Path_Units
  FOR INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
--
-- Insert a initial production start record for each new production unit.
--
Declare @Path Int,@Pu Int
Select @Path = Path_Id,@Pu = PU_Id FROM INSERTED
If (select count(*) from PrdExec_Path_Unit_Starts where Path_Id = @Path and PU_Id = @Pu) = 0
  INSERT INTO PrdExec_Path_Unit_Starts  (Start_Time,End_Time,User_Id,Path_Id,PU_Id)
 	 Values('Jan 1, 1970 00:00',NULL,1,@Path,@Pu)

GO
CREATE TRIGGER [dbo].[PrdExec_Path_Units_TableFieldValue_Del]
 ON  [dbo].[PrdExec_Path_Units]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.PEPU_Id
 WHERE tfv.TableId = 30

GO
CREATE TRIGGER [dbo].[PrdExec_Path_Units_History_Ins]
 ON  [dbo].[PrdExec_Path_Units]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 452
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into PrdExec_Path_Unit_History
 	  	   (Is_Production_Point,Is_Schedule_Point,Path_Id,PEPU_Id,PU_Id,Unit_Order,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Is_Production_Point,a.Is_Schedule_Point,a.Path_Id,a.PEPU_Id,a.PU_Id,a.Unit_Order,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[PrdExec_Path_Units_History_Upd]
 ON  [dbo].[PrdExec_Path_Units]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 452
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into PrdExec_Path_Unit_History
 	  	   (Is_Production_Point,Is_Schedule_Point,Path_Id,PEPU_Id,PU_Id,Unit_Order,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Is_Production_Point,a.Is_Schedule_Point,a.Path_Id,a.PEPU_Id,a.PU_Id,a.Unit_Order,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[PrdExec_Path_Units_History_Del]
 ON  [dbo].[PrdExec_Path_Units]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 452
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into PrdExec_Path_Unit_History
 	  	   (Is_Production_Point,Is_Schedule_Point,Path_Id,PEPU_Id,PU_Id,Unit_Order,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Is_Production_Point,a.Is_Schedule_Point,a.Path_Id,a.PEPU_Id,a.PU_Id,a.Unit_Order,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
