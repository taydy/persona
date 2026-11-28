import { sessionDisplayTitle } from '../core/SessionNaming';
import { agentFamilySummary, runningSubagents } from '../core/AgentRowPreview';
import { Colors } from '../design/Colors';
import { tr } from '../design/Strings';
import { Symbols } from '../design/Symbols';
import { Tokens } from '../design/Tokens';
import { AgentWorkspace } from '../models/AgentWorkspace';
import { ResourceRow } from '../models/Wire';
import { Haptics } from '../platform/Haptics';

@ComponentV2
export struct FamilyDisclosureButton {
  @Require @Param label: string;
  @Require @Param count: number;
  @Require @Param summary: string;
  @Require @Param identity: string;
  @Require @Param expanded: boolean;
  @Require @Param owner: string;
  @Event toggle: () => void = () => {};

  build() {
    Button({ type:ButtonType.Normal, buttonStyle:ButtonStyleMode.TEXTUAL }) {
      Row({ space:Tokens.fine }) {
        Text(this.label + ' ' + this.count).fontSize(Tokens.caption).maxFontScale(Tokens.interfaceFontMaxScale)
          .fontWeight(FontWeight.Medium).fontColor(Colors.secondary).maxLines(1)
          .textOverflow({overflow:TextOverflow.Ellipsis}).flexShrink(1)
        SymbolGlyph(this.expanded ? Symbols.down : Symbols.expand).fontSize(10).fontColor([Colors.secondary])
      }.padding({left:Tokens.fine,top:Tokens.fine,bottom:Tokens.fine})
    }.padding(0).backgroundColor(Color.Transparent)
      .constraintSize({minHeight:Tokens.touch,minWidth:Tokens.touch})
      .margin({right:Tokens.inset})
      .accessibilityText([this.owner,this.summary,tr(this.expanded ? 'agent_collapse' : 'agent_expand')].join(' · '))
      .onClick(() => this.toggle()).id('agents.family.' + this.identity)
  }
}

@ComponentV2
export struct AgentFamilyLine {
  @Require @Param workspace: AgentWorkspace;
  @Require @Param row: ResourceRow;
  @Param inset: number = Tokens.page;
  @Param expandable: boolean = true;
  @Param preferTab: boolean = false;
  private title(row: ResourceRow): string {
    return (this.preferTab ? sessionDisplayTitle(row.title,row.data(),true) : row.title) || tr('agent_untitled');
  }
  @Param accessoryTime: string = '';
  @BuilderParam content: (hasDisclosure: boolean) => void;
  @Event open: () => void = () => {};

  @Computed get children(): ResourceRow[] { return this.workspace.foldedChildren(this.row); }
  @Computed get sides(): number { return this.children.filter(child => this.workspace.relations.kind(child) === 'side').length; }
  @Computed get summary(): string {
    const children = this.children, sides = this.sides;
    return agentFamilySummary(sides, children.length - sides, children.filter(child => child.state === 'needs_you').length,
      children.filter(child => child.state === 'working').length, tr);
  }

  @Computed get ownerCaption(): string {
    const root = this.workspace.relations.root(this.row);
    if (!root) return '';
    return tr('agent_family_owner')
      .replace('{kind}',tr(this.workspace.relations.kind(this.row) === 'side' ? 'relation_side' : 'relation_task'))
      .replace('{parent}',() => this.title(root));
  }

  @Computed get activityNote(): string {
    if (this.summary) return this.expandable ? '' : this.summary;
    if (this.ownerCaption) return '';
    const count = runningSubagents(this.row.data());
    return count ? tr('agent_subagents_running').replace('{count}', String(count)) : '';
  }

  build() {
    if (this.expandable && this.summary) {
      Row() {
        Column() { this.content(true) }.layoutWeight(1)
        Column() {
          FamilyDisclosureButton({label:tr(!this.sides ? 'relation_task' : this.sides === this.children.length ? 'relation_side' : 'relation_related'),
            count:this.children.length,summary:this.summary,expanded:this.workspace.familyExpanded(this.row),
            identity:this.row.key(),owner:this.title(this.row),
            toggle:() => { Haptics.tap(); this.workspace.toggleFamily(this.row); }})
          if (this.accessoryTime) Text(this.accessoryTime).fontSize(Tokens.caption).fontColor(Colors.secondary)
            .maxFontScale(Tokens.interfaceFontMaxScale).maxLines(1).margin({right:Tokens.inset})
        }.constraintSize({maxWidth:'36%'}).alignItems(HorizontalAlign.End)
      }.width('100%').alignItems(VerticalAlign.Top)
    } else if (this.ownerCaption || this.activityNote) {
      Column() {
        if (this.ownerCaption) {
          Row({space:Tokens.gap}) {
            Row().width(9).height(8).border({width:{left:1,bottom:1},color:Colors.secondary,radius:{bottomLeft:3}})
            Text(this.ownerCaption).fontSize(Tokens.caption).maxFontScale(Tokens.interfaceFontMaxScale).fontColor(Colors.secondary)
              .maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis}).layoutWeight(1)
          }.width('100%').padding({left:this.inset,right:Tokens.page,top:Tokens.gap})
            .accessibilityGroup(true).accessibilityText(this.ownerCaption)
            .onClick(() => this.open()).id('agents.relation.' + this.row.key())
        }
        this.content(false)
        if (this.activityNote) {
          Text(this.activityNote).fontSize(Tokens.caption).fontColor(Colors.secondary)
            .padding({left:this.inset,right:Tokens.page,bottom:Tokens.gap})
        }
      }.width('100%').alignItems(HorizontalAlign.Start)
    } else {
      this.content(false)
    }
  }
}
