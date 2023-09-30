CREATE TABLE [dbo].[Sheet_Variables] (
    [Sheet_Id]                 INT                  NOT NULL,
    [Title]                    [dbo].[Varchar_Desc] NULL,
    [Var_Id]                   INT                  NULL,
    [Var_Order]                INT                  NOT NULL,
    [Activity_Order]           INT                  NULL,
    [Execution_Start_Duration] INT                  NULL,
    [Target_Duration]          INT                  NULL,
    [Title_Var_Order_Id]       INT                  NULL,
    [Activity_Alias]           VARCHAR (20)         NULL,
    [AutoComplete_Duration]    INT                  NULL,
    [External_URL_link]        VARCHAR (255)        NULL,
    [Open_URL_Configuration]   INT                  NULL,
    [Password]                 VARCHAR (50)         NULL,
    [User_Login]               VARCHAR (50)         NULL,
    CONSTRAINT [SheetVars_PK_ShtIdOrder] PRIMARY KEY CLUSTERED ([Sheet_Id] ASC, [Var_Order] ASC),
    CONSTRAINT [SheetVars_CC_VarIdTitle] CHECK ([Var_Id] IS NULL OR [Title] IS NULL AND (NOT [Var_Id] IS NULL OR NOT [Title] IS NULL)),
    CONSTRAINT [SheetVars_FK_ShtId] FOREIGN KEY ([Sheet_Id]) REFERENCES [dbo].[Sheets] ([Sheet_Id]),
    CONSTRAINT [SheetVars_FK_VarId] FOREIGN KEY ([Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id]),
    CONSTRAINT [SheetVars_UC_ShtIdOrder] UNIQUE NONCLUSTERED ([Sheet_Id] ASC, [Var_Order] ASC)
);


GO
CREATE NONCLUSTERED INDEX [SheetVars_IDX_ShtId]
    ON [dbo].[Sheet_Variables]([Sheet_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [SheetVars_IDX_VarId]
    ON [dbo].[Sheet_Variables]([Var_Id] ASC);


GO
CREATE TRIGGER [dbo].[Sheet_Variables_Upd]
 ON  [dbo].[Sheet_Variables]
  FOR UPDATE 
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 insert into Sheet_Display_Options_Changed
 Select i.Var_Order,i.Sheet_Id,--i.value 
 case  	 
 	 when i.Var_Order > 0 then 'activities-app-service'
End
 from inserted i join deleted d on d.Var_Order = i.Var_Order and d.Sheet_Id = i.Sheet_Id
WHERE EXISTS (SELECT 1 FROM Sheet_display_options where display_option_id = 461 And Sheet_Id = i.Sheet_Id )
