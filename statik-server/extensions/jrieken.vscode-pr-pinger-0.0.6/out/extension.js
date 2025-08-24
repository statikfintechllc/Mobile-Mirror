"use strict";
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = void 0;
const vscode = require("vscode");
const graphql_1 = require("@octokit/graphql");
function activate(context) {
    const item = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 1);
    let session;
    vscode.commands.registerCommand('pr.promptLogin', async () => {
        session = await vscode.authentication.getSession('github', ['repo'], { createIfNone: true });
        updateItem();
    });
    vscode.commands.registerCommand('pr.show', async (pr) => {
        vscode.env.openExternal(vscode.Uri.parse(pr.url));
        item.hide();
    });
    let currentShow = undefined;
    // monitor focus/unfocus to "nudge harder" after a context switch
    let lastGone;
    context.subscriptions.push(vscode.window.onDidChangeWindowState(e => {
        if (!e.focused) {
            // gone
            lastGone = Date.now();
            return;
        }
        if (lastGone && Date.now() - lastGone > 1000 * 60 * 5) {
            // back after 5 minutes
            updateItem(true);
        }
    }));
    async function updateItem(afterAway) {
        if (!session) {
            item.text = 'Not Logged In';
            item.command = 'pr.promptLogin';
            item.show();
            return;
        }
        if (currentShow) {
            // already showing a PR
            return;
        }
        const tooLongAgo = Date.now() - 1000 * 60 * 60 * 24 * 4;
        const data = await (0, graphql_1.graphql)(query, { headers: { authorization: `Bearer ${session.accessToken}` } });
        const prs = data.repository.pullRequests.edges.map(edge => edge.node)
            .filter(needsTeamReview) // from team
            .filter(pr => pr.author.login !== session.account.label) // not YOU
            .map(pr => ({ pr, date: new Date(pr.createdAt) }))
            .filter(({ date }) => date.getTime() > tooLongAgo) // not dated
            .sort((a, b) => b.date.getTime() - a.date.getTime()); // sorted
        if (prs.length === 0) {
            return;
        }
        // Unless forced you only need to review with a certain chance
        if (!afterAway) {
            const chance = Math.ceil(prs.length / 7);
            if (Math.random() > chance) {
                return;
            }
        }
        // pick a random PR so that not everyone gets the same one
        const n = Math.floor(Math.random() * prs.length);
        const pr = prs[n].pr;
        item.text = makeLabel(pr);
        item.tooltip = new vscode.MarkdownString(`[${pr.title}](${pr.url}) needs your review. Thanks $(heart-filled)`, true);
        item.command = { command: 'pr.show', title: 'Show PR', arguments: [pr] };
        item.backgroundColor = afterAway ? new vscode.ThemeColor('statusBarItem.warningBackground') : undefined;
        item.show();
        // refresh every 20 seconds 
        const checkHandle = setInterval(async function () {
            const data = await (0, graphql_1.graphql)(check, {
                pr: pr.number,
                headers: { authorization: `Bearer ${session.accessToken}` },
            });
            if (!needsTeamReview(data.repository.pullRequest)) {
                currentShow.dispose();
            }
        }, 1000 * 20);
        currentShow = new vscode.Disposable(() => {
            clearInterval(checkHandle);
            currentShow = undefined;
            item.hide();
        });
    }
    vscode.authentication.getSession('github', ['repo']).then(_session => {
        session = _session;
        updateItem();
    });
    const handle = setInterval(updateItem, 1000 * 60 * 10); // update every 10 minutes
    context.subscriptions.push(new vscode.Disposable(() => clearInterval(handle)));
}
exports.activate = activate;
function makeLabel(pr) {
    const style = vscode.workspace.getConfiguration('prpinger').get('presentation');
    if (style === 'number') {
        return `$(git-pull-request) #${pr.number}`;
    }
    const ignore = new Set(['`', '.', ':']);
    const vowels = new Set(['a', 'e', 'i', 'o', 'u']);
    const newTitle = [];
    for (const ch of pr.title) {
        if (ignore.has(ch)) {
            break;
        }
        if (newTitle.length > 8 && !/\w/.test(ch)) {
            break;
        }
        if (newTitle.length > 15) {
            break;
        }
        if (!vowels.has(ch)) {
            newTitle.push(ch);
        }
    }
    return `$(git-pull-request) ${newTitle.join('')}`;
}
function needsTeamReview(pr) {
    return pr.authorAssociation === 'MEMBER'
        && !pr.isDraft
        && pr.reviewRequests.totalCount === 0
        && pr.reviews.totalCount === 0
        && pr.assignees.nodes.length === 1 && pr.assignees.nodes[0].login === pr.author.login; // our PR bot assigns the poster as owner -> we use that as filter
}
const query = `{
  repository(owner: "microsoft", name: "vscode") {
    pullRequests(
      first: 30
      states: OPEN
      orderBy: {field: CREATED_AT, direction: DESC}
    ) {
      edges {
        node {
          title
		  number
          url
          createdAt
          authorAssociation
          author {
            login
          }
          assignees(first:5) {
            nodes {
              login
            }
          }
          isDraft
          reviewRequests(last: 1) {
            totalCount
          }
          reviews(last:1) {
            totalCount
          }
        }
      }
    }
  }
}`;
const check = `query validate($pr: Int!) {
  repository(owner: "microsoft", name: "vscode") {
    pullRequest(number: $pr) {
      authorAssociation
      author {
        login
      }
      assignees(first:5) {
        nodes {
          login
        }
      }
      isDraft
      reviewRequests(last: 1) {
        totalCount
      }
      reviews(last: 1) {
        totalCount
      }
    }
  }
}`;
//# sourceMappingURL=extension.js.map