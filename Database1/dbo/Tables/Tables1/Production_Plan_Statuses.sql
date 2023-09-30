CREATE TABLE [dbo].[Production_Plan_Statuses] (
    [PP_Status_Id]          INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Allow_Edit]            TINYINT        NULL,
    [Color_Id]              INT            NULL,
    [Movable]               BIT            CONSTRAINT [Production_Plan_Statuses_DF_Movable] DEFAULT ((0)) NOT NULL,
    [PP_Status_Desc_Global] VARCHAR (50)   NULL,
    [PP_Status_Desc_Local]  VARCHAR (50)   NOT NULL,
    [PP_Status_Desc]        AS             (case when (@@options&(512))=(0) then isnull([PP_Status_Desc_Global],[PP_Status_Desc_Local]) else [PP_Status_Desc_Local] end),
    [Status_Order]          INT            NULL,
    [Status_Group]          NVARCHAR (400) NULL,
    CONSTRAINT [PP_Statuses_PK_PPStatus_Id] PRIMARY KEY CLUSTERED ([PP_Status_Id] ASC),
    CONSTRAINT [Production_Plan_Statuses_FK_ColorId] FOREIGN KEY ([Color_Id]) REFERENCES [dbo].[Colors] ([Color_Id]),
    CONSTRAINT [PP_Statuses_UC_PPStatus_DescLocal] UNIQUE NONCLUSTERED ([PP_Status_Desc_Local] ASC)
);


GO
CREATE TRIGGER [dbo].[Production_Plan_Statuses_TableFieldValue_Del]
 ON  [dbo].[Production_Plan_Statuses]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.PP_Status_Id
 WHERE tfv.TableId = 34
