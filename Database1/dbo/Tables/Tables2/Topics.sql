CREATE TABLE [dbo].[Topics] (
    [Calculation_Id]      INT                     NULL,
    [Event_Type]          TINYINT                 NOT NULL,
    [Sampling_Interval]   [dbo].[Smallint_Offset] NOT NULL,
    [Sampling_Offset]     [dbo].[Smallint_Offset] NOT NULL,
    [Sampling_Window]     INT                     NULL,
    [SubscriptionTableId] INT                     NULL,
    [Topic_Desc]          VARCHAR (70)            NULL,
    [Topic_Id]            INT                     NOT NULL,
    CONSTRAINT [Topics_PK_TopicId] PRIMARY KEY CLUSTERED ([Topic_Id] ASC),
    CONSTRAINT [Topics_FK_ETId] FOREIGN KEY ([Event_Type]) REFERENCES [dbo].[Event_Types] ([ET_Id]),
    CONSTRAINT [Topics_FK_MessageId] FOREIGN KEY ([Topic_Id]) REFERENCES [dbo].[Message_Types] ([Message_Id])
);

