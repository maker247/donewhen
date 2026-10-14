<script>
	import { activeWorkspace } from '$lib/store.js';
	import { api } from '$lib/api.js';
	import { showToast } from '$lib/ui.js';

	let members = $state([]);
	let loading = $state(true);
	let confirmId = $state('');

	let email = $state('');
	let role = $state('member');
	let addErr = $state('');
	let adding = $state(false);

	const isOwner = $derived($activeWorkspace?.role === 'owner');
	const canAdmin = $derived(['owner', 'admin'].includes($activeWorkspace?.role));
	const ownerCount = $derived(members.filter((m) => m.role === 'owner').length);

	async function load() {
		if (!$activeWorkspace) return;
		loading = true;
		try {
			members = (await api.members($activeWorkspace.id)) || [];
		} catch (e) {
			showToast('Could not load members: ' + (e?.message || e), 'error');
			members = [];
		} finally {
			loading = false;
		}
	}

	let loadedFor = $state(null);
	$effect(() => {
		const id = $activeWorkspace?.id;
		if (!id || loadedFor === id) return;
		loadedFor = id;
		load();
	});

	// Mirrors the server's own guard (internal/store/workspaces.go RemoveMember):
	// a workspace can never be left without an owner.
	function isLastOwner(m) {
		return m.role === 'owner' && ownerCount <= 1;
	}

	function canChangeRole(m) {
		if (!canAdmin) return false;
		if (m.role === 'owner' && !isOwner) return false;
		return true;
	}

	async function updateRole(m, newRole) {
		if (m.role === newRole) return;
		try {
			await api.addMember($activeWorkspace.id, { email: m.email, role: newRole });
			await load();
			showToast(`Updated ${m.email} to ${newRole}`);
		} catch (e) {
			showToast(e.message || 'Could not update role.', 'error');
			await load();
		}
	}

	async function addMember() {
		addErr = '';
		if (!email.trim()) {
			addErr = 'Email is required.';
			return;
		}
		adding = true;
		try {
			await api.addMember($activeWorkspace.id, { email: email.trim(), role });
			email = '';
			role = 'member';
			await load();
			showToast('Member added');
		} catch (e) {
			addErr = e.message || 'Could not add member.';
		} finally {
			adding = false;
		}
	}

	async function removeMember(userId) {
		if (confirmId !== userId) {
			confirmId = userId;
			return;
		}
		confirmId = '';
		try {
			await api.removeMember($activeWorkspace.id, userId);
			await load();
			showToast('Member removed');
		} catch (e) {
			showToast(e.message || 'Could not remove member.', 'error');
		}
	}
</script>

<div class="settings-wrap">
	<div class="settings-head">
		<h1 class="settings-h1">Members & Permissions</h1>
		<p class="settings-lede">
			{$activeWorkspace?.name} · {members.length} member{members.length === 1 ? '' : 's'}. You are <b>{$activeWorkspace?.role}</b>.
		</p>
	</div>

	<section class="settings-panel">
		<div class="settings-panel-h">Members<span class="n">{members.length}</span></div>
		{#if loading}
			<p class="settings-hint">Loading…</p>
		{:else}
			{#each members as m (m.userId)}
				<div class="settings-row">
					<div style="flex: 1; min-width: 0;">
						<div style="font-weight: 500;">{m.email}</div>
					</div>

					{#if canAdmin && canChangeRole(m) && !isLastOwner(m)}
						<select
							class="select settings-input-short"
							value={m.role}
							onchange={(e) => updateRole(m, e.currentTarget.value)}
							title="Change role"
						>
							{#if isOwner}<option value="owner">owner</option>{/if}
							<option value="admin">admin</option>
							<option value="member">member</option>
							<option value="viewer">viewer</option>
						</select>
					{:else}
						<span class="pill" class:accent={m.role === 'owner'}>{m.role}</span>
					{/if}

					{#if canAdmin}
						{#if confirmId === m.userId}
							<span class="settings-confirm">
								Remove {m.email}?
								<button class="btn danger settings-btn-sm" onclick={() => removeMember(m.userId)}>Confirm</button>
								<button class="btn ghost settings-btn-sm" onclick={() => (confirmId = '')}>Cancel</button>
							</span>
						{:else if isLastOwner(m)}
							<span class="settings-hint">last owner</span>
						{:else}
							<button class="btn ghost settings-btn-sm" onclick={() => removeMember(m.userId)}>Remove</button>
						{/if}
					{/if}
				</div>
			{:else}
				<p class="settings-hint">No members listed.</p>
			{/each}
		{/if}
	</section>

	{#if canAdmin}
		<section class="settings-panel">
			<div class="settings-panel-h">Add a member</div>
			<div class="settings-inline">
				<input class="input" style="width:240px" placeholder="existing account email" bind:value={email} />
				<select class="select settings-input-short" bind:value={role}>
					<option value="viewer">viewer</option>
					<option value="member">member</option>
					<option value="admin">admin</option>
					{#if isOwner}<option value="owner">owner</option>{/if}
				</select>
				<button class="btn primary" onclick={addMember} disabled={adding}>{adding ? 'Adding…' : 'Add'}</button>
			</div>
			{#if addErr}<span class="settings-err">{addErr}</span>{/if}
			<span class="settings-hint">
				The account must already exist — create it on the server with <span class="settings-mono">donewhen user &lt;email&gt; &lt;pass&gt;</span>.
			</span>
		</section>
	{/if}

	<section class="settings-panel">
		<div class="settings-panel-h">Roles & Permissions Reference</div>
		<div style="display: flex; flex-direction: column; gap: 12px; font-size: var(--t-sm);">
			<div class="settings-row" style="align-items: flex-start; padding: 10px 0;">
				<div style="width: 90px; flex: none;"><span class="pill accent">owner</span></div>
				<div style="color: var(--ink-2); line-height: 1.45;">
					<b style="color: var(--ink);">Full Workspace Control</b> — manage workspace settings, invite & remove members, grant/revoke owner role, delete workspace.
				</div>
			</div>
			<div class="settings-row" style="align-items: flex-start; padding: 10px 0;">
				<div style="width: 90px; flex: none;"><span class="pill">admin</span></div>
				<div style="color: var(--ink-2); line-height: 1.45;">
					<b style="color: var(--ink);">Workspace Administration</b> — edit workspace name/prefix/AI name, manage members (admin, member, viewer), and force-bypass Done-When gates.
				</div>
			</div>
			<div class="settings-row" style="align-items: flex-start; padding: 10px 0;">
				<div style="width: 90px; flex: none;"><span class="pill">member</span></div>
				<div style="color: var(--ink-2); line-height: 1.45;">
					<b style="color: var(--ink);">Standard Read & Write</b> — create, edit, move, and delete issues, epics, criteria, and documentation; post comments.
				</div>
			</div>
			<div class="settings-row" style="align-items: flex-start; padding: 10px 0;">
				<div style="width: 90px; flex: none;"><span class="pill">viewer</span></div>
				<div style="color: var(--ink-2); line-height: 1.45;">
					<b style="color: var(--ink);">Read & Comment Only</b> — read access to all tasks, epics, criteria, and artifacts. Allowed to post comments to collaborate, but cannot create, modify, or delete tasks or documents.
				</div>
			</div>
		</div>
	</section>
</div>
