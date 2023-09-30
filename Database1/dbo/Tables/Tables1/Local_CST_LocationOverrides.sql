CREATE TABLE [dbo].[Local_CST_LocationOverrides] (
    [LOID]             INT          IDENTITY (1, 1) NOT NULL,
    [LocationId]       INT          NOT NULL,
    [Origin_Status]    INT          NOT NULL,
    [Origin_CleanType] VARCHAR (50) NULL,
    [Origin_PPID]      INT          NULL,
    [Origin_Prod_Id]   INT          NULL,
    [New_Status]       INT          NOT NULL,
    [New_CleanType]    VARCHAR (50) NULL,
    [New_PPID]         INT          NULL,
    [New_Prod_Id]      INT          NULL,
    [UserId]           INT          NOT NULL,
    [Timestamp]        DATETIME     NOT NULL,
    [CommentId]        INT          NULL,
    CONSTRAINT [FK_Local_CST_LocationOverrides_Prod_Units_Base] FOREIGN KEY ([LocationId]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [FK_Local_CST_LocationOverrides_Production_Plan] FOREIGN KEY ([New_PPID]) REFERENCES [dbo].[Production_Plan] ([PP_Id]),
    CONSTRAINT [FK_Local_CST_LocationOverrides_Products_Base] FOREIGN KEY ([Origin_Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [FK_Local_CST_LocationOverrides_Products_Base1] FOREIGN KEY ([New_Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id])
);


GO
CREATE NONCLUSTERED INDEX [IDX_CST_LO_Timestamp]
    ON [dbo].[Local_CST_LocationOverrides]([Timestamp] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_CST_LO_TimestampApplianceId]
    ON [dbo].[Local_CST_LocationOverrides]([LocationId] ASC, [Timestamp] ASC);

