/*
=======================================================================================================================================
Page: /users
=======================================================================================================================================
Purpose: Everybody in the database - real accounts and guest placeholders - with how many
         leagues each one runs and belongs to, and when they were last seen.
=======================================================================================================================================
*/

import { redirect } from 'next/navigation';
import { get_users } from '@/lib/api';
import { load } from '@/lib/load';
import { PageTitle } from '@/components/ui';
import ErrorPanel from '@/components/error_panel';
import UsersTable from './users_table';

export const dynamic = 'force-dynamic';

export default async function UsersPage() {
  const result = await load(get_users());

  if (!result.ok && result.expired) redirect('/login');
  if (!result.ok) return <ErrorPanel code={result.code} message={result.error} />;

  const users = result.data.users;

  const real = users.filter((user) => !user.is_guest).length;
  const organisers = users.filter((user) => user.leagues_created > 0).length;

  return (
    <>
      <PageTitle
        title="Users"
        subtitle={
          `${real} real accounts and ${users.length - real} guest placeholders. ` +
          `${organisers} have created a league. Guests are hidden until you ask for them.`
        }
      />

      <UsersTable users={users} />
    </>
  );
}
