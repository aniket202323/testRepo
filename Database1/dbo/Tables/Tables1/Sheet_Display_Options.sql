CREATE TABLE [dbo].[Sheet_Display_Options] (
    [Binary_Id]         INT            NULL,
    [Display_Option_Id] INT            NOT NULL,
    [Sheet_Id]          INT            NOT NULL,
    [Value]             VARCHAR (7000) NOT NULL,
    CONSTRAINT [SheetDOpt_PK_SheetIdDispOptId] PRIMARY KEY NONCLUSTERED ([Sheet_Id] ASC, [Display_Option_Id] ASC),
    CONSTRAINT [FK_SheetDisOpt_Binaries] FOREIGN KEY ([Binary_Id]) REFERENCES [dbo].[Binaries] ([Binary_Id]),
    CONSTRAINT [SheetDOpt_FK_DispOptId] FOREIGN KEY ([Display_Option_Id]) REFERENCES [dbo].[Display_Options] ([Display_Option_Id]),
    CONSTRAINT [SheetDOpt_FK_SheetId] FOREIGN KEY ([Sheet_Id]) REFERENCES [dbo].[Sheets] ([Sheet_Id])
);


GO
CREATE NONCLUSTERED INDEX [IX_SHEETDISPLAYOPTIONS_SHEETID_DISPLAYOPTIONID]
    ON [dbo].[Sheet_Display_Options]([Sheet_Id] ASC, [Display_Option_Id] ASC)
    INCLUDE([Value]);


GO
CREATE TRIGGER [dbo].[Sheet_Display_Options_Upd]
 ON  [dbo].[Sheet_Display_Options]
  FOR UPDATE,INSERT 
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 insert into Sheet_Display_Options_Changed
 Select i.Display_Option_Id,i.Sheet_Id,--i.value 
 case  	 
 	 when i.Display_Option_Id = 445 then 'activities-app-service, activities-service'
 	 when i.Display_Option_Id = 446 then 'mymachine-service-impl, downtime-app-service, mes-service-impl,  productionmetrics-app-service'
 	 when i.Display_Option_Id = 458 then 'activities-app-service, activities-service'
End
 from inserted i join deleted d on d.Display_Option_Id = i.Display_Option_Id and d.Sheet_Id = i.Sheet_Id
 Where d.Value <> i.value and i.Display_Option_Id in(445,446,458)
UNION
 Select i.Display_Option_Id,i.Sheet_Id,--i.value 
 case  	 
 	 when i.Display_Option_Id = 445 then 'activities-app-service, activities-service'
 	 when i.Display_Option_Id = 446 then 'mymachine-service-impl, downtime-app-service, mes-service-impl, productionmetrics-app-service'
 	 when i.Display_Option_Id = 458 then 'activities-app-service, activities-service'
End
 from inserted i 
 Where  i.Display_Option_Id in(445,446,458)
 and not exists (select 1 from deleted)

GO
CREATE TRIGGER [dbo].[fnBF_ApiFindAvailableUnitsAndEventTypes_Sheet_Display_Options_Sync]
  	  ON [dbo].[Sheet_Display_Options]
  	  FOR INSERT, UPDATE, DELETE
AS  	  
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
UPDATE SITE_Parameters SET [Value] = 1 where parm_Id = 700 and [Value]=0;
--Insert Into Message_Log_Detail (Message,Message_Log_Id) Select '[[Sheet_Display_Options]]',12345
