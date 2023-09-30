CREATE TABLE [dbo].[Sheet_Type_Display_Options] (
    [STDO_Id]                 INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Display_Option_Default]  VARCHAR (7000) NULL,
    [Display_Option_Id]       INT            NOT NULL,
    [Display_Option_Max]      INT            NULL,
    [Display_Option_Min]      INT            NULL,
    [Display_Option_Required] BIT            CONSTRAINT [Display_Options_DF_Required] DEFAULT ((0)) NOT NULL,
    [Sheet_Type_Id]           TINYINT        NOT NULL,
    CONSTRAINT [Sheet_Type_Display_Options_PK2] PRIMARY KEY NONCLUSTERED ([STDO_Id] ASC),
    CONSTRAINT [SheetTypeDisOpt_FK_DispOptId] FOREIGN KEY ([Display_Option_Id]) REFERENCES [dbo].[Display_Options] ([Display_Option_Id]),
    CONSTRAINT [SheetTypeDisplayOptions_FK_SheetType] FOREIGN KEY ([Sheet_Type_Id]) REFERENCES [dbo].[Sheet_Type] ([Sheet_Type_Id])
);


GO
CREATE NONCLUSTERED INDEX [Sheet_Type_Display_Options_IX_TypeDO]
    ON [dbo].[Sheet_Type_Display_Options]([Sheet_Type_Id] ASC, [Display_Option_Id] ASC);

